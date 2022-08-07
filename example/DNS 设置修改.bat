@echo off

:: �ٶ� ���� DNS
:: https://dudns.baidu.com/

:: Google ���� NDS
:: https://developers.google.com/speed/public-dns/docs/using

:: ������ ���� DNS
:: https://www.alidns.com/

echo ���ñ������ӵ� DNS ����
netsh interface ipv4 set dnsserver name="��������" source=static address=180.76.76.76 register=primary
netsh interface ipv4 add dnsserver name="��������" address=8.8.8.8
netsh interface ipv4 add dnsserver name="��������" address=223.5.5.5

netsh interface ipv6 set dnsserver name="��������" source=static address=2400:da00::6666 register=primary
netsh interface ipv6 add dnsserver name="��������" address=2001:4860:4860::8888
netsh interface ipv6 add dnsserver name="��������" address=2400:3200::1

echo �鿴�������ӵ� DNS ����
netsh interface ipv4 show dns name="��������"
netsh interface ipv6 show dns name="��������"

pause
exit
