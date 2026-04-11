#!/bin/bash
echo "========================================"
echo " MotivAI Backend - Setup"
echo "========================================"

echo ""
echo "[1] Kutubxonalar o'rnatilmoqda..."
pip install -r requirements.txt || { echo "XATO: pip install"; exit 1; }

echo ""
echo "[2] Database yaratilmoqda..."
psql -U postgres -c "CREATE DATABASE motivai;" 2>/dev/null || echo "   (allaqachon mavjud - OK)"

echo ""
echo "[3] Migratsiyalar qo'llanilmoqda..."
alembic upgrade head || { echo "XATO: Migration. .env faylini tekshiring"; exit 1; }

echo ""
echo "========================================"
echo " TAYYOR! Server ishga tushirilmoqda..."
echo " Docs: http://localhost:8000/docs"
echo "========================================"
echo ""
uvicorn main:app --reload --host 0.0.0.0 --port 8000
