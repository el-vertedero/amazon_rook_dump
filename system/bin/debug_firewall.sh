#!/system/bin/sh
IPTABLES=/system/bin/iptables
$IPTABLES -A INPUT -i wlan0 -p tcp --dport ssh -j ACCEPT
$IPTABLES -A INPUT -i wlan0 -p tcp -m tcp --dport 11007 -j ACCEPT
$IPTABLES -A INPUT -i wlan0 -p icmp --icmp-type echo-request -j ACCEPT
