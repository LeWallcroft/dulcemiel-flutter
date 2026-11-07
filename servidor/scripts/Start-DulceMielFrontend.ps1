param([switch]$Worker)

$ErrorActionPreference = 'Stop'
$projectRoot = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$webRoot = (Resolve-Path (Join-Path $projectRoot '..\..\..\Calidad\Proyecto Final - Dulce Miel\Desarrollo\dulcemiel-web\frontend')).Path
$logDirectory = Join-Path (Join-Path $projectRoot 'servidor') 'logs'
$logFile = Join-Path $logDirectory 'frontend.log'
$pidFile = Join-Path $logDirectory 'frontend.pid'
$frontendUrl = 'http://localhost:4200'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

if ($Worker) {
    Set-Location $webRoot
    & npm.cmd start -- --host 127.0.0.1 *>> $logFile
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath (Join-Path $webRoot 'package.json'))) {
    throw "No se encontro el frontend web en la ruta esperada: $webRoot"
}
if (-not (Get-Command npm.cmd -ErrorAction SilentlyContinue)) {
    throw 'Node.js/npm no esta disponible en PATH.'
}

$existingListener = Get-NetTCPConnection -State Listen -LocalPort 4200 -ErrorAction SilentlyContinue | Select-Object -First 1
if ($existingListener) {
    try {
        Invoke-WebRequest -Uri $frontendUrl -TimeoutSec 3 -UseBasicParsing | Out-Null
        Write-Host "Frontend web ya activo: $frontendUrl"
        Start-Process $frontendUrl
        exit 0
    } catch {
        throw 'El puerto 4200 ya esta ocupado, pero no responde como frontend Dulce Miel.'
    }
}

if (-not (Test-Path -LiteralPath (Join-Path $webRoot 'node_modules'))) {
    Write-Host 'Instalando dependencias del frontend con npm ci...'
    Push-Location $webRoot
    try { & npm.cmd ci --no-audit --no-fund } finally { Pop-Location }
    if ($LASTEXITCODE -ne 0) { throw 'npm ci fallo; revisa la conexion y package-lock.json.' }
}

$powershellExe = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
if (-not $powershellExe) { $powershellExe = (Get-Command pwsh.exe -ErrorAction Stop).Source }
$argumentLine = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Worker"
$process = Start-Process -FilePath $powershellExe -ArgumentList $argumentLine `
    -WorkingDirectory $webRoot -WindowStyle Hidden -PassThru
Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ascii

for ($attempt = 0; $attempt -lt 120; $attempt++) {
    Start-Sleep -Seconds 1
    try {
        Invoke-WebRequest -Uri $frontendUrl -TimeoutSec 3 -UseBasicParsing | Out-Null
        Write-Host "Frontend web iniciado: $frontendUrl"
        Write-Host "Registro: $logFile"
        Start-Process $frontendUrl
        exit 0
    } catch { }
    if (-not (Get-Process -Id $process.Id -ErrorAction SilentlyContinue)) { break }
}

throw "No se confirmo el inicio del frontend. Consulta $logFile"
