@echo off
setlocal
set "PROJECT_DIR=%~dp0"
set "SERVER_DIR=%PROJECT_DIR%servidor"

if not exist "%SERVER_DIR%\scripts\Start-DulceMielServer.ps1" (
  echo No se encontro el servidor en "%SERVER_DIR%".
  pause
  exit /b 1
)

if not exist "%SERVER_DIR%\.env" (
  copy "%SERVER_DIR%\.env.example" "%SERVER_DIR%\.env" >nul
  echo Se creo servidor\.env desde la plantilla.
  echo Completa SQL Server, Firebase Admin y Backblaze antes de ejecutar nuevamente.
  pause
  exit /b 1
)

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%SERVER_DIR%\scripts\Start-DulceMielServer.ps1"
if errorlevel 1 (
  echo No se pudo iniciar el servidor. Revisa Docker, SQL Server y servidor\.env.
  pause
  exit /b 1
)

echo Servidor Dulce Miel disponible en http://127.0.0.1:5000/api/
pause
