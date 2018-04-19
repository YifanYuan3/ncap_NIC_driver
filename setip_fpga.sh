IP=10.150.4.243
NETMASK=255.255.255.0
BROADCAST=10.150.4.255
GATEWAY=10.150.4.1
DNS=10.2.2.10
ETHERNET="eth0"

./run_eth_app_p2p.sh 
ifconfig $ETHERNET $IP netmask $NETMASK broadcast $BROADCAST 
route add default gw $GATEWAY dev $ETHERNET
echo "nameserver $DNS" >> /etc/resolv.conf
cat /etc/resolv.conf
wait 2
ifconfig $ETHERNET down
wait 3
ifconfig $ETHERNET up
ifconfig
