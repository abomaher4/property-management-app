@echo off
echo Starting uvicorn server...
start cmd /k "uvicorn app:app --reload"
timeout /t 5 /nobreak >nul
echo Creating admin user...
python create_admin_user.py
pause
