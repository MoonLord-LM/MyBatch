@echo off



git config --local core.autocrlf false
git config --local core.safecrlf false
git config --local core.ignorecase false

git config --local core.quotepath false
git config --local i18n.logoutputencoding utf-8
git config --local i18n.commitencoding utf-8

echo.
git config --local --list
echo.



pause
exit
