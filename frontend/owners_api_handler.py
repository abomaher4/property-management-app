from PySide6.QtCore import QObject, Signal, Slot
import requests
import traceback

class OwnersAPIHandler(QObject):
    ownersFetched = Signal(list)
    operationSuccess = Signal(str)
    operationFailed = Signal(str)

    def __init__(self, access_token="", parent=None):
        super().__init__(parent)
        self.access_token = access_token
        self.base_url = "http://127.0.0.1:8000/owners/"

    def _make_request_headers(self):
        return {
            "Authorization": f"Bearer {self.access_token}",
            "Content-Type": "application/json",
            "Accept": "application/json"
        }

    def _handle_error(self, action, error, response=None):
        error_msg = f"[{action}] فشل: "
        if response is not None:
            try:
                error_msg += str(response.json().get("detail", response.text))
            except ValueError:
                error_msg += str(response.text)
        else:
            error_msg += str(error)
        print(error_msg)
        traceback.print_exc()
        self.operationFailed.emit(error_msg)

    @Slot()
    def fetchOwners(self):
        try:
            headers = self._make_request_headers()
            response = requests.get(self.base_url, headers=headers)
            if response.status_code == 200:
                owners_data = response.json()
                processed_owners = []
                for owner in owners_data:
                    processed_owners.append({
                        "id": owner.get("id", 0),
                        "name": owner.get("name", ""),
                        "owner_type": owner.get("owner_type", ""),
                        "id_number": owner.get("id_number", ""),
                        "nationality": owner.get("nationality", ""),
                        "main_phone": owner.get("main_phone", ""),
                        "secondary_phone": owner.get("secondary_phone", ""),
                        "email": owner.get("email", ""),
                        "address": owner.get("address", ""),
                        "ownership_percentage": owner.get("ownership_percentage", 0),
                        "iban": owner.get("iban", ""),
                        "birth_date": owner.get("birth_date", ""),
                        "notes": owner.get("notes", ""),
                        "agent_name": owner.get("agent_name", ""),
                        "units_count": owner.get("units_count", 0)
                    })
                self.ownersFetched.emit(processed_owners)
            else:
                self._handle_error("fetchOwners", None, response)
        except Exception as e:
            self._handle_error("fetchOwners", e)

    @Slot(str, str, str, str, str, float, str, str, str, str, str, str, str)
    def addOwner(
        self, name, owner_type, id_number, nationality, main_phone, ownership_percentage,
        secondary_phone="", email="", address="", iban="", birth_date=None, notes="", agent_name=""
    ):
        print("DEBUG: addOwner called:", name, owner_type, id_number, nationality, main_phone, ownership_percentage)
        try:
            headers = self._make_request_headers()
            data = {
                "name": name,
                "owner_type": owner_type,
                "id_number": id_number,
                "nationality": nationality,
                "main_phone": main_phone,
                "ownership_percentage": float(ownership_percentage)
            }
            if secondary_phone: data["secondary_phone"] = secondary_phone
            if email: data["email"] = email
            if address: data["address"] = address
            if iban: data["iban"] = iban
            if birth_date: data["birth_date"] = birth_date
            if notes: data["notes"] = notes
            if agent_name: data["agent_name"] = agent_name

            response = requests.post(
                self.base_url,
                headers=headers,
                json=data
            )
            print("DEBUG: API Response Status:", response.status_code, "Body:", response.text)
            if response.status_code in (200, 201):
                self.operationSuccess.emit("تمت إضافة المالك بنجاح")
            else:
                self._handle_error("addOwner", None, response)
        except Exception as e:
            self._handle_error("addOwner", e)

    @Slot(int, str, str, str, str, str, float, str, str, str, str, str, str, str)
    def updateOwner(
        self, owner_id, name, owner_type, id_number, nationality, main_phone, ownership_percentage,
        secondary_phone="", email="", address="", iban="", birth_date=None, notes="", agent_name=""
    ):
        try:
            headers = self._make_request_headers()
            data = {
                "name": name,
                "owner_type": owner_type,
                "id_number": id_number,
                "nationality": nationality,
                "main_phone": main_phone,
                "ownership_percentage": float(ownership_percentage)
            }
            if secondary_phone: data["secondary_phone"] = secondary_phone
            if email: data["email"] = email
            if address: data["address"] = address
            if iban: data["iban"] = iban
            if birth_date: data["birth_date"] = birth_date
            if notes: data["notes"] = notes
            if agent_name: data["agent_name"] = agent_name

            response = requests.put(
                f"{self.base_url}{owner_id}/",
                headers=headers,
                json=data
            )

            if response.status_code == 200:
                self.operationSuccess.emit("تم تحديث بيانات المالك بنجاح")
            else:
                self._handle_error("updateOwner", None, response)
        except Exception as e:
            self._handle_error("updateOwner", e)

    @Slot(int)
    def deleteOwner(self, owner_id):
        try:
            headers = self._make_request_headers()
            response = requests.delete(
                f"{self.base_url}{owner_id}/",
                headers=headers
            )
            if response.status_code == 204:
                self.operationSuccess.emit("تم حذف المالك بنجاح")
            else:
                self._handle_error("deleteOwner", None, response)
        except Exception as e:
            self._handle_error("deleteOwner", e)

    @Slot()
    def testSlot(self):
        print("=== testSlot called from QML! ===")
