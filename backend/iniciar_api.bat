@echo off
cls
echo ========================================================
echo               Motora API - Inicializador
echo ========================================================
echo.

python --version >nul 2>&1
if errorlevel 1 (
    echo [ERRO] Python nao foi encontrado no PATH do Windows!
    echo.
    echo Baixe o Python em: https://www.python.org/downloads/
    echo Marque a opcao: Add python.exe to PATH
    echo.
    pause
    exit /b 1
)

echo [1/3] Instalando dependencias...
python -m pip install -r requirements.txt
if errorlevel 1 (
    echo [ERRO] Falha ao instalar dependencias com o pip.
    pause
    exit /b 1
)

echo.
echo [2/3] Populando banco de dados SQLite...
python seed_data.py

echo.
echo [3/3] Iniciando servidor FastAPI em http://localhost:8000
echo Swagger: http://localhost:8000/docs
echo Pressione Ctrl + C para encerrar.
echo.
python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
pause
