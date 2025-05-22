from PySide6.QtCore import QObject, Signal, Slot, Property, QUrl

import requests

import os

import json

class OwnersApiHandler(QObject):

    # الإشارات
    dataLoaded = Signal(list) # إشارة جديدة لتحميل البيانات
    ownerAdded = Signal()
    ownerUpdated = Signal()
    ownerDeleted = Signal(int) # تعديل لإرسال معرف المالك المحذوف
    errorOccurred = Signal(str)
    paginationChanged = Signal() # إشارة جديدة لتغيير معلومات الصفحات

    def __init__(self):
        super().__init__()
        self._owners = []
        self._owners_loaded = False
        self._isLoading = False
        self._api_base_url = "http://localhost:8000"

        # إضافة متغيرات جديدة لنظام الصفحات
        self._current_page = 1
        self._per_page = 25  # تعديل القيمة الافتراضية إلى 25
        self._total_pages = 1
        self._total_items = 0
        self._filter_name = ""
        self._filter_registration_number = ""
        self._filter_nationality = ""

    # الخصائص الأساسية
    def owners(self):
        return self._owners

    def isLoading(self):
        return self._isLoading

    # خصائص جديدة لنظام الصفحات
    def current_page(self):
        return self._current_page

    def per_page(self):
        return self._per_page

    def total_pages(self):
        return self._total_pages

    def total_items(self):
        return self._total_items

    # تعريف الخصائص
    ownersList = Property(list, owners, notify=dataLoaded)
    isLoadingProp = Property(bool, isLoading, constant=True)
    currentPage = Property(int, current_page, notify=paginationChanged)
    perPage = Property(int, per_page, notify=paginationChanged)
    totalPages = Property(int, total_pages, notify=paginationChanged)
    totalItems = Property(int, total_items, notify=paginationChanged)

    @Slot(bool)
    def get_owners(self, force_reload=False):
        """تحميل الملاك من السيرفر (الطريقة القديمة)"""
        if self._owners_loaded and not force_reload:
            self.dataLoaded.emit(self._owners)
            return

        self._isLoading = True
        try:
            # استخدام الطريقة الجديدة مع نظام الصفحات
            self.get_filtered_owners("", "", "", self._current_page, self._per_page)
        except Exception as e:
            self.errorOccurred.emit(f"خطأ في جلب الملاك: {str(e)}")
        finally:
            self._isLoading = False

    @Slot()
    def refresh(self):
        """تحديث البيانات من السيرفر"""
        self._owners_loaded = False
        self.get_owners(force_reload=True)

    @Slot(int)
    def set_per_page(self, per_page):
        """تعيين عدد العناصر في الصفحة"""
        if per_page != self._per_page:
            self._per_page = per_page
            self._current_page = 1  # إعادة الصفحة للبداية
            self.paginationChanged.emit()
            # استدعاء دالة تحميل البيانات مع القيمة الجديدة
            self.get_filtered_owners(self._filter_name, self._filter_registration_number, self._filter_nationality,
                                   self._current_page, self._per_page)

    @Slot(str, str, str, int, int)
    def get_filtered_owners(self, filter_name="", filter_registration_number="", filter_nationality="", page=1, per_page=None):
        """تحميل الملاك من السيرفر مع دعم التصفية والصفحات"""
        self._isLoading = True
        self._current_page = page
        
        # استخدام قيمة per_page من المعاملات إذا توفرت، وإلا استخدام القيمة المخزنة
        if per_page is not None:
            self._per_page = per_page
            
        self._filter_name = filter_name
        self._filter_registration_number = filter_registration_number
        self._filter_nationality = filter_nationality

        params = {
            "page": page,
            "per_page": self._per_page
        }

        if filter_name:
            params["filter_name"] = filter_name

        if filter_registration_number:
            params["filter_registration_number"] = filter_registration_number

        if filter_nationality:
            params["filter_nationality"] = filter_nationality

        try:
            response = requests.get(f"{self._api_base_url}/owners/", params=params)
            data = response.json()

            if isinstance(data, dict):
                # معالجة الاستجابة الجديدة بتنسيق الصفحات
                if "data" in data:
                    self._owners = data.get("data", [])
                    self._total_items = data.get("total", 0)
                    self._current_page = data.get("page", 1)
                    self._total_pages = data.get("total_pages", 1)
                elif "owners" in data:
                    self._owners = data["owners"]
            elif isinstance(data, list):
                self._owners = data
                self._total_pages = 1
                self._total_items = len(data)

            self._owners_loaded = True
            self.dataLoaded.emit(self._owners)
            self.paginationChanged.emit()

        except Exception as e:
            self.errorOccurred.emit(f"خطأ في جلب الملاك: {str(e)}")
        finally:
            self._isLoading = False

    @Slot()
    def next_page(self):
        """الانتقال للصفحة التالية"""
        if self._current_page < self._total_pages:
            self._current_page += 1
            self.paginationChanged.emit()
            self.get_filtered_owners(self._filter_name, self._filter_registration_number, self._filter_nationality,
                                   self._current_page, self._per_page)

    @Slot()
    def previous_page(self):
        """الانتقال للصفحة السابقة"""
        if self._current_page > 1:
            self._current_page -= 1
            self.paginationChanged.emit()
            self.get_filtered_owners(self._filter_name, self._filter_registration_number, self._filter_nationality,
                                   self._current_page, self._per_page)

    @Slot(str, str, str, str, str, str, 'QVariant')
    def add_owner(self, name, registration_number, nationality, iban, agent_name, notes, attachments):
        """إضافة مالك جديد"""
        self._isLoading = True
        try:
            attachments_list = self._to_pylist_of_dicts(attachments)
            payload = {
                "name": name,
                "registration_number": registration_number,
                "nationality": nationality,
                "iban": iban,
                "agent_name": agent_name,
                "notes": notes,
                "attachments": attachments_list,
            }

            response = requests.post(f"{self._api_base_url}/owners/", json=payload)
            data = response.json()

            if response.ok:
                self.ownerAdded.emit()
                # تحديث الكاش
                if "owner" in data:
                    self._owners.append(data["owner"])
                else:
                    self._owners_loaded = False
                    self.get_filtered_owners(self._filter_name, self._filter_registration_number, self._filter_nationality,
                                         self._current_page, self._per_page)
            else:
                self.errorOccurred.emit(data.get("message", "فشل إضافة مالك"))
        except Exception as e:
            self.errorOccurred.emit(f"فشل الإضافة: {str(e)}")
        finally:
            self._isLoading = False

    @Slot(int, str, str, str, str, str, str, 'QVariant')
    def update_owner(self, owner_id, name, registration_number, nationality, iban, agent_name, notes, attachments):
        """تعديل بيانات مالك"""
        self._isLoading = True
        try:
            attachments_list = self._to_pylist_of_dicts(attachments)
            payload = {
                "name": name,
                "registration_number": registration_number,
                "nationality": nationality,
                "iban": iban,
                "agent_name": agent_name,
                "notes": notes,
                "attachments": attachments_list,
            }

            response = requests.put(f"{self._api_base_url}/owners/{owner_id}", json=payload)
            data = response.json()

            if response.ok:
                self.ownerUpdated.emit()
                # تحديث العنصر في الكاش
                for idx, o in enumerate(self._owners):
                    if o["id"] == owner_id:
                        self._owners[idx].update(payload)
                        if "attachments" in data:
                            self._owners[idx]["attachments"] = data["attachments"]
                        break
                else:
                    # إذا لم يتم العثور على المالك في الكاش
                    self._owners_loaded = False
                    self.get_filtered_owners(self._filter_name, self._filter_registration_number, self._filter_nationality,
                                         self._current_page, self._per_page)
            else:
                self.errorOccurred.emit(data.get("message", "فشل تعديل المالك"))
        except Exception as e:
            self.errorOccurred.emit(f"فشل التعديل: {str(e)}")
        finally:
            self._isLoading = False

    @Slot(str)
    def delete_owner(self, owner_id):
        """حذف مالك"""
        self._isLoading = True
        try:
            owner_id_int = int(owner_id)
            response = requests.delete(f"{self._api_base_url}/owners/{owner_id}")
            data = response.json()

            if response.ok:
                # حذف المالك من الكاش
                self._owners = [o for o in self._owners if o["id"] != owner_id_int]
                self.ownerDeleted.emit(owner_id_int)
                # إذا كانت الصفحة الحالية فارغة وهناك صفحات سابقة، انتقل للصفحة السابقة
                if len(self._owners) == 0 and self._current_page > 1:
                    self.previous_page()
                elif self._current_page > 1 or self._filter_name or self._filter_registration_number or self._filter_nationality:
                    # تحديث البيانات والصفحات
                    self.get_filtered_owners(self._filter_name, self._filter_registration_number, self._filter_nationality,
                                         self._current_page, self._per_page)
            else:
                self.errorOccurred.emit(data.get("message", "فشل حذف المالك"))
        except Exception as e:
            self.errorOccurred.emit(f"فشل الحذف: {str(e)}")
        finally:
            self._isLoading = False

    @Slot(str, str)
    def download_file(self, url, target_path):
        """تنزيل ملف مرفق"""
        try:
            # إزالة بروتوكول file:/// إذا كان موجودًا
            if target_path.startswith("file:///"):
                target_path = target_path[8:]

            # التأكد من وجود المجلد
            os.makedirs(os.path.dirname(target_path), exist_ok=True)

            # تنزيل الملف
            response = requests.get(url, stream=True)
            if response.ok:
                with open(target_path, 'wb') as f:
                    for chunk in response.iter_content(chunk_size=1024):
                        if chunk:
                            f.write(chunk)
                self.errorOccurred.emit("تم تنزيل الملف بنجاح")
            else:
                self.errorOccurred.emit("فشل في تنزيل الملف")
        except Exception as e:
            self.errorOccurred.emit(f"خطأ في تنزيل الملف: {str(e)}")

    @Slot(int)
    def get_owner_details(self, owner_id):
        """جلب تفاصيل مالك محدد"""
        # التحقق أولاً من وجود التفاصيل في الكاش
        for o in self._owners:
            if o["id"] == owner_id and "attachments" in o and o["attachments"]:
                return o

        # إذا لم تكن التفاصيل موجودة، اجلبها من السيرفر
        try:
            response = requests.get(f"{self._api_base_url}/owners/{owner_id}")
            data = response.json()

            # تحديث الكاش
            for idx, o in enumerate(self._owners):
                if o["id"] == owner_id:
                    self._owners[idx] = data
                    break
            else:
                self._owners.append(data)

            self.dataLoaded.emit(self._owners)
            return data
        except Exception as e:
            self.errorOccurred.emit(f"خطأ في جلب تفاصيل المالك: {str(e)}")
            return None

    def _to_pylist_of_dicts(self, attachments):
        """تحويل قائمة QML إلى قائمة بايثون"""
        if isinstance(attachments, str):
            try:
                attachments = json.loads(attachments)
            except Exception:
                attachments = []

        if attachments is None:
            return []

        try:
            if hasattr(attachments, 'toVariant'):
                attachments = attachments.toVariant()
        except Exception:
            pass

        pylist = []
        try:
            for a in attachments:
                if hasattr(a, "toVariant"):
                    a = a.toVariant()
                if not isinstance(a, dict):
                    a = dict(a)
                pylist.append(a)
        except Exception:
            pylist = attachments if isinstance(attachments, list) else []

        return pylist
