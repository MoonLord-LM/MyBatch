@echo off

set targetDate="2025-02-01 00:00:00"

powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ChildItem -Recurse | %%{ if (-not $_.PSIsContainer) { $_.LastWriteTime = [datetime]::Parse('%targetDate%') } }"

pause
exit
