@echo off
REM Build attractplus via WSL + MXE, deploy to Z:\Arcade\attractmode
REM Double-click to run - uses WSL (wsl --install if needed)
REM First run: ~1-4 hours. Subsequent: ~5-15 min.

cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0build-and-deploy-wsl.ps1"
pause
