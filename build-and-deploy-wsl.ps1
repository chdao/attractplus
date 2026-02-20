# Build attractplus via WSL + MXE, deploy to Z:\Arcade\attractmode
# Run from PowerShell: .\build-and-deploy-wsl.ps1
# Requires: WSL installed (wsl --install)
# First run: ~1-4 hours (MXE build). Subsequent runs: ~5-15 min.

$ErrorActionPreference = "Stop"
$repoRoot = $PSScriptRoot
$deployPath = "Z:\Arcade\attractmode"

Write-Host "Building Attract-Mode Plus via WSL + MXE..." -ForegroundColor Cyan
Write-Host "Deploy target: $deployPath" -ForegroundColor Cyan
Write-Host ""

# Convert Windows path to WSL path (use forward slashes - backslashes get mangled by PowerShell)
$winPath = $repoRoot -replace '\\', '/'
$wslPath = (wsl wslpath -a $winPath).Trim()

wsl -e bash -c "cd '$wslPath' && SKIP_ZIP=1 bash util/win/build-static-release.sh"

if ($LASTEXITCODE -ne 0) {
    Write-Host ""
    Write-Host "Build FAILED." -ForegroundColor Red
    exit 1
}

Write-Host ""
Write-Host "Deploying to $deployPath..." -ForegroundColor Yellow
Copy-Item -Path "$repoRoot\attractplus.exe" -Destination "$deployPath\attractplus.exe" -Force
Copy-Item -Path "$repoRoot\attractplus-console.exe" -Destination "$deployPath\attractplus-console.exe" -Force

Write-Host ""
Write-Host "Done. Static executables deployed to $deployPath" -ForegroundColor Green
