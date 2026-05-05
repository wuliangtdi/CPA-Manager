param(
    [string]$Name = "CPAManagerUsageService"
)

$ErrorActionPreference = "Stop"

$principal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
if (-not $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    throw "Please run PowerShell as Administrator before uninstalling the Windows service."
}

$existing = Get-Service -Name $Name -ErrorAction SilentlyContinue
if ($existing) {
    Stop-Service -Name $Name -ErrorAction SilentlyContinue
    sc.exe delete $Name | Out-Null
    Write-Host "Removed service: $Name"
} else {
    Write-Host "Service not found: $Name"
}
