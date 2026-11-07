$ErrorActionPreference = 'Stop'
$serverRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$pidFile = Join-Path $serverRoot 'logs\servidor.pid'
$projectJarName = 'backend-0.0.1-SNAPSHOT.jar'
$listener = Get-NetTCPConnection -State Listen -LocalPort 5000 -ErrorAction SilentlyContinue |
    Select-Object -First 1
if ($listener) {
    $javaProcess = Get-CimInstance Win32_Process -Filter "ProcessId = $($listener.OwningProcess)" -ErrorAction SilentlyContinue
    if ($javaProcess -and $javaProcess.CommandLine -like "*$projectJarName*") {
        Stop-Process -Id $listener.OwningProcess -Force
        Write-Host 'Servidor Dulce Miel detenido.'
    }
}
if (-not (Test-Path -LiteralPath $pidFile)) {
    if (-not $listener) { Write-Host 'No se encontro el servidor en el puerto 5000.' }
    exit 0
}
$savedPid = Get-Content -LiteralPath $pidFile | Select-Object -First 1
if ($savedPid -match '^\d+$') {
    $serverProcess = Get-Process -Id ([int]$savedPid) -ErrorAction SilentlyContinue
    if ($serverProcess -and $serverProcess.ProcessName -eq 'powershell') {
        Stop-Process -Id $serverProcess.Id -Force
    }
}
Remove-Item -LiteralPath $pidFile -Force -ErrorAction SilentlyContinue
