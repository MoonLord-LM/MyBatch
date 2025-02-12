@echo off

set "creationDate=2025-02-01 00:00:00"
set "writeDate=2025-02-01 00:00:00"
set "accessDate=2025-02-01 00:00:00"

powershell -NoProfile -ExecutionPolicy Bypass -Command ^
    "Get-ChildItem -Recurse | Where-Object { !$_.PSIsContainer } | ForEach-Object {" ^
    "$_.CreationTime = [datetime]::Parse('%creationDate%');" ^
    "$_.LastWriteTime = [datetime]::Parse('%writeDate%');" ^
    "$_.LastAccessTime = [datetime]::Parse('%accessDate%');" ^
    "}"

pause
exit
