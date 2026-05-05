param(
    [string]$Version = "dev",
    [string]$GoExe = "go"
)

$ErrorActionPreference = "Stop"

$RepoRoot = Resolve-Path (Join-Path $PSScriptRoot "..")
$DistDir = Join-Path $RepoRoot "dist"
$ReleaseDir = Join-Path $RepoRoot "release\windows"
$EmbeddedPanel = Join-Path $RepoRoot "usage-service\internal\httpapi\web\management.html"
$ReleaseRoot = Join-Path $RepoRoot "release"

if (-not ([System.IO.Path]::GetFullPath($ReleaseDir).StartsWith([System.IO.Path]::GetFullPath($ReleaseRoot)))) {
    throw "Refusing to remove release directory outside repository release root: $ReleaseDir"
}

Write-Host "Building management panel..."
Push-Location $RepoRoot
try {
    $env:VERSION = $Version
    npm ci
    npm run build
} finally {
    Pop-Location
}

Write-Host "Building Windows usage service..."
if (Test-Path -LiteralPath $ReleaseDir) {
    Remove-Item -LiteralPath $ReleaseDir -Recurse -Force
}
New-Item -ItemType Directory -Path $ReleaseDir | Out-Null
New-Item -ItemType Directory -Path (Join-Path $ReleaseDir "data") | Out-Null

$PanelBackup = Join-Path ([System.IO.Path]::GetTempPath()) ("cpa-manager-panel-" + [guid]::NewGuid().ToString("N") + ".html")
Copy-Item -LiteralPath $EmbeddedPanel -Destination $PanelBackup -Force
Copy-Item -LiteralPath (Join-Path $DistDir "index.html") -Destination $EmbeddedPanel -Force

Push-Location (Join-Path $RepoRoot "usage-service")
try {
    $env:CGO_ENABLED = "0"
    $env:GOOS = "windows"
    $env:GOARCH = "amd64"
    & $GoExe build -trimpath -ldflags="-s -w" -o (Join-Path $ReleaseDir "cpa-manager.exe") .\cmd\cpa-manager
} finally {
    Pop-Location
    Copy-Item -LiteralPath $PanelBackup -Destination $EmbeddedPanel -Force
    Remove-Item -LiteralPath $PanelBackup -Force -ErrorAction SilentlyContinue
    Remove-Item Env:\CGO_ENABLED -ErrorAction SilentlyContinue
    Remove-Item Env:\GOOS -ErrorAction SilentlyContinue
    Remove-Item Env:\GOARCH -ErrorAction SilentlyContinue
    Remove-Item Env:\VERSION -ErrorAction SilentlyContinue
}

Copy-Item -LiteralPath (Join-Path $RepoRoot "scripts\start-windows.ps1") -Destination $ReleaseDir -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot "scripts\install-windows-service.ps1") -Destination $ReleaseDir -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot "scripts\uninstall-windows-service.ps1") -Destination $ReleaseDir -Force
Copy-Item -LiteralPath (Join-Path $RepoRoot "README_WINDOWS_CN.md") -Destination $ReleaseDir -Force

Write-Host ""
Write-Host "Done: $ReleaseDir"
Write-Host "Run:  powershell -ExecutionPolicy Bypass -File `"$ReleaseDir\start-windows.ps1`""
