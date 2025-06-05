@echo off
set /p message="Message du commit : "
git add .
git commit -m "%message%"
git push
pause
