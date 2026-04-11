@echo off
echo ========================================
echo  MotivAI Backend - Setup
echo ========================================

echo.
echo [1] Kutubxonalar o'rnatilmoqda...
pip install -r requirements.txt
if errorlevel 1 (
    echo XATO: pip install muvaffaqiyatsiz
    pause
    exit /b 1
)

echo.
echo [2] Database yaratilmoqda...
psql -U postgres -c "CREATE DATABASE motivai;" 2>nul
echo    (agar "already exists" desa - bu normal)

echo.
echo [3] Migratsiyalar qo'llanilmoqda...
alembic upgrade head
if errorlevel 1 (
    echo XATO: Migration muvaffaqiyatsiz
    echo .env faylidagi DATABASE_URL va SYNC_DATABASE_URL ni tekshiring
    pause
    exit /b 1
)

echo.
echo ========================================
echo  TAYYOR! Server ishga tushirilmoqda...
echo  Docs: http://localhost:8000/docs
echo ========================================
echo.
uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause
