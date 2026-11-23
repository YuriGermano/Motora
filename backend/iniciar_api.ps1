Write-Host "========================================================" -ForegroundColor Cyan
Write-Host "             Motora API - Inicializador                 " -ForegroundColor Cyan
Write-Host "========================================================" -ForegroundColor Cyan
Write-Host ""

$pythonCmd = Get-Command python -ErrorAction SilentlyContinue

if (-not $pythonCmd) {
    Write-Host "[ERRO] Python nao foi encontrado no sistema!" -ForegroundColor Red
    Write-Host "Por favor, instale o Python em https://www.python.org/downloads/" -ForegroundColor Yellow
    Write-Host "IMPORTANTE: Marque a opcao 'Add python.exe to PATH' durante a instalacao." -ForegroundColor Yellow
    exit 1
}

Write-Host "[1/3] Verificando e instalando dependencias (FastAPI, Uvicorn, etc)..." -ForegroundColor Green
python -m pip install -r requirements.txt

Write-Host ""
Write-Host "[2/3] Populando banco de dados de demonstracao..." -ForegroundColor Green
python seed_data.py

# Se houver celular Android conectado via USB, redireciona a porta 8000 automaticamente
$adbPath = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
if (Test-Path $adbPath) {
    & $adbPath reverse tcp:8000 tcp:8000 2>$null
} else {
    adb reverse tcp:8000 tcp:8000 2>$null
}

Write-Host ""
Write-Host "[3/3] Iniciando API em http://localhost:8000 ..." -ForegroundColor Green
Write-Host "Documentacao Swagger: http://localhost:8000/docs" -ForegroundColor Yellow
Write-Host "Pressione Ctrl + C para encerrar." -ForegroundColor Gray
Write-Host ""

python -m uvicorn main:app --reload --host 0.0.0.0 --port 8000
