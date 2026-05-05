param(
    [string]$HttpAddr = "0.0.0.0:18317",
    [string]$DataDir = "",
    [string]$CpaUrl = "",
    [string]$ManagementKey = "",
    [string]$CorsOrigins = "*"
)

$ErrorActionPreference = "Stop"

$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath = Join-Path $BaseDir "cpa-manager.exe"
if (-not (Test-Path -LiteralPath $ExePath)) {
    $ExePath = Join-Path (Resolve-Path (Join-Path $BaseDir "..")) "usage-service\cpa-manager.exe"
}
if (-not (Test-Path -LiteralPath $ExePath)) {
    throw "cpa-manager.exe not found next to this script."
}

if ($DataDir -eq "") {
    $DataDir = Join-Path $BaseDir "data"
}
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null

$env:HTTP_ADDR = $HttpAddr
$env:USAGE_DATA_DIR = $DataDir
$env:USAGE_DB_PATH = Join-Path $DataDir "usage.sqlite"
$env:USAGE_CORS_ORIGINS = $CorsOrigins

if ($CpaUrl -ne "") {
    $env:CPA_UPSTREAM_URL = $CpaUrl
}
if ($ManagementKey -ne "") {
    $env:CPA_MANAGEMENT_KEY = $ManagementKey
}

Write-Host "CPA Manager Usage Service"
Write-Host "HTTP: http://localhost:$($HttpAddr.Split(':')[-1])/management.html"
Write-Host "Data: $DataDir"
Write-Host "Press Ctrl+C to stop."
& $ExePath
