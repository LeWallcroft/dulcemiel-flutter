param([switch]$Worker)

$ErrorActionPreference = 'Stop'
$serverRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')).Path
$logDirectory = Join-Path $serverRoot 'logs'
$logFile = Join-Path $logDirectory 'servidor.log'
$pidFile = Join-Path $logDirectory 'servidor.pid'
$healthUrl = 'http://127.0.0.1:5000/api/health'
$databaseCheckUrl = 'http://127.0.0.1:5000/api/productos'
New-Item -ItemType Directory -Path $logDirectory -Force | Out-Null

if ($Worker) {
    Set-Location $serverRoot
    & .\mvnw.cmd '-Dmaven.test.skip=true' 'package' *>> $logFile
    if ($LASTEXITCODE -ne 0) { exit $LASTEXITCODE }
    & java -jar '.\target\backend-0.0.1-SNAPSHOT.jar' *>> $logFile
    exit $LASTEXITCODE
}

if (-not (Test-Path -LiteralPath (Join-Path $serverRoot '.env'))) {
    throw 'Falta servidor\.env. Crea el archivo desde .env.example y completa los valores locales.'
}
$envFile = Join-Path $serverRoot '.env'
$firebaseCredentialLine = Get-Content -LiteralPath $envFile | Where-Object { $_ -match '^\s*FIREBASE_CREDENTIALS_FILE\s*=' } | Select-Object -First 1
$firebaseCredentialPath = if ($firebaseCredentialLine) { ($firebaseCredentialLine -split '=', 2)[1].Trim().Trim('"').Trim("'") } else { '' }
if ([string]::IsNullOrWhiteSpace($firebaseCredentialPath) -and
    [string]::IsNullOrWhiteSpace($env:GOOGLE_APPLICATION_CREDENTIALS)) {
    Write-Warning 'Firebase Admin no tiene credenciales configuradas; el intercambio de token Firebase fallara hasta configurar FIREBASE_CREDENTIALS_FILE o ADC.'
} elseif (-not [string]::IsNullOrWhiteSpace($firebaseCredentialPath) -and
    -not (Test-Path -LiteralPath $firebaseCredentialPath)) {
    Write-Warning 'La ruta de FIREBASE_CREDENTIALS_FILE no existe; el intercambio de token Firebase fallara hasta corregirla.'
}
if (-not (Get-Command docker -ErrorAction SilentlyContinue)) { throw 'Docker no esta disponible en PATH.' }
$container = docker inspect --format '{{.State.Running}}' sql_servidor 2>$null
if ($LASTEXITCODE -ne 0 -or $container -ne 'true') {
    throw 'El contenedor sql_servidor no esta iniciado. Inicia SQL Server en Docker.'
}
if (-not (Get-NetTCPConnection -State Listen -LocalPort 1433 -ErrorAction SilentlyContinue)) {
    throw 'SQL Server no esta escuchando en el puerto local 1433.'
}

try {
    Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2 | Out-Null
    $databaseCheck = Invoke-RestMethod -Uri $databaseCheckUrl -TimeoutSec 5
    if ($databaseCheck.success -ne $true) { throw 'La API esta activa, pero no confirmo la consulta SQL.' }
    Write-Host "El servidor ya esta activo: $healthUrl"
    Write-Host 'Conexion con SQL Server verificada mediante /api/productos.'
    exit 0
} catch { }

if (Test-Path -LiteralPath $pidFile) {
    $savedPid = Get-Content -LiteralPath $pidFile -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($savedPid -match '^\d+$' -and (Get-Process -Id ([int]$savedPid) -ErrorAction SilentlyContinue)) {
        throw "El proceso PID $savedPid sigue activo, pero la API no responde. Revisa $logFile"
    }
}

$argumentLine = "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`" -Worker"
$powershellExe = (Get-Command powershell.exe -ErrorAction SilentlyContinue).Source
if (-not $powershellExe) { $powershellExe = (Get-Command pwsh.exe -ErrorAction Stop).Source }
$process = Start-Process -FilePath $powershellExe `
    -ArgumentList $argumentLine -WorkingDirectory $serverRoot -WindowStyle Hidden -PassThru
Set-Content -LiteralPath $pidFile -Value $process.Id -Encoding ascii

for ($attempt = 0; $attempt -lt 90; $attempt++) {
    Start-Sleep -Seconds 1
    try {
        $health = Invoke-RestMethod -Uri $healthUrl -TimeoutSec 2
        $databaseCheck = Invoke-RestMethod -Uri $databaseCheckUrl -TimeoutSec 5
        if ($health.success -eq $true -and $databaseCheck.success -eq $true) {
            Write-Host 'Servidor Dulce Miel iniciado.'
            Write-Host 'Conexion con SQL Server verificada mediante /api/productos.'
            Write-Host 'API: http://127.0.0.1:5000/api/'
            Write-Host 'Android Emulator: http://10.0.2.2:5000/api/'
            Write-Host "Registro: $logFile"
            exit 0
        }
    } catch { }
    if (-not (Get-Process -Id $process.Id -ErrorAction SilentlyContinue)) { break }
}
throw "No se confirmo el inicio del servidor. Revisa $logFile"
