param(
    [string]$Name = "CPAManagerUsageService",
    [string]$DisplayName = "CPA Manager Usage Service",
    [string]$HttpAddr = "0.0.0.0:18317",
    [string]$DataDir = "",
    [string]$CpaUrl = "",
    [string]$ManagementKey = "",
    [string]$CorsOrigins = "*"
)

$ErrorActionPreference = "Stop"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Please run PowerShell as Administrator before installing the Windows service."
}

$BaseDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$ExePath = Join-Path $BaseDir "cpa-manager.exe"
if (-not (Test-Path -LiteralPath $ExePath)) {
    throw "cpa-manager.exe not found next to this script."
}

if ($DataDir -eq "") {
    $DataDir = Join-Path $BaseDir "data"
}
New-Item -ItemType Directory -Path $DataDir -Force | Out-Null

$settings = @{
    CPA_MANAGER_SERVICE_NAME = $Name
    HTTP_ADDR = $HttpAddr
    USAGE_DATA_DIR = $DataDir
    USAGE_DB_PATH = (Join-Path $DataDir "usage.sqlite")
    USAGE_CORS_ORIGINS = $CorsOrigins
}
if ($CpaUrl -ne "") {
    $settings.CPA_UPSTREAM_URL = $CpaUrl
}
if ($ManagementKey -ne "") {
    $settings.CPA_MANAGEMENT_KEY = $ManagementKey
}

$existing = Get-Service -Name $Name -ErrorAction SilentlyContinue
if ($existing) {
    Stop-Service -Name $Name -ErrorAction SilentlyContinue
    sc.exe delete $Name | Out-Null
    Start-Sleep -Seconds 2
}

New-Service `
    -Name $Name `
    -DisplayName $DisplayName `
    -BinaryPathName "`"$ExePath`" -service-name `"$Name`"" `
    -StartupType Automatic `
    -Description "Consumes CPA usage events and serves the CPA Manager usage panel."

$serviceKey = "HKLM:\SYSTEM\CurrentControlSet\Services\$Name"
$environment = @()
foreach ($item in $settings.GetEnumerator()) {
    $environment += "$($item.Key)=$($item.Value)"
}
New-ItemProperty -Path $serviceKey -Name Environment -PropertyType MultiString -Value $environment -Force | Out-Null

Start-Service -Name $Name

Write-Host "Installed and started: $DisplayName"
Write-Host "Open: http://localhost:$($HttpAddr.Split(':')[-1])/management.html"
