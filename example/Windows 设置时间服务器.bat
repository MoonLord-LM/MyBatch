@echo off

w32tm /tz

w32tm /config /manualpeerlist:"time.google.com" /syncfromflags:manual /reliable:yes /update
w32tm /resync

w32tm /config /manualpeerlist:"time.windows.com" /syncfromflags:manual /reliable:yes /update
w32tm /resync

w32tm /config /manualpeerlist:"pool.ntp.org" /syncfromflags:manual /reliable:yes /update
w32tm /resync

net stop w32time
net start w32time

w32tm /query /status

pause
exit
