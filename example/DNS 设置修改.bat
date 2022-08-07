@echo off

:: 百度 公共 DNS
:: https://dudns.baidu.com/

:: Google 公共 NDS
:: https://developers.google.com/speed/public-dns/docs/using

:: 阿里云 公共 DNS
:: https://www.alidns.com/

echo 设置本地连接的 DNS 配置
netsh interface ipv4 set dnsserver name="本地连接" source=static address=180.76.76.76 register=primary
netsh interface ipv4 add dnsserver name="本地连接" address=8.8.8.8
netsh interface ipv4 add dnsserver name="本地连接" address=223.5.5.5

netsh interface ipv6 set dnsserver name="本地连接" source=static address=2400:da00::6666 register=primary
netsh interface ipv6 add dnsserver name="本地连接" address=2001:4860:4860::8888
netsh interface ipv6 add dnsserver name="本地连接" address=2400:3200::1

echo 查看本地连接的 DNS 配置
netsh interface ipv4 show dns name="本地连接"
netsh interface ipv6 show dns name="本地连接"

pause
exit
