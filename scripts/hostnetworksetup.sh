#!/bin/sh

if [ $# -eq 0 ];
then
	echo "ERROR : no id provided"
	exit 1
fi
if [ $1 -gt 32767 ] || [ $1 -lt 0 ];
then
        echo "invalid id"
        exit 1
fi
id=$1
beg=0
suf=$(expr $id \* 2)
if [ "$suf" -gt 255 ];
then
	beg=$(expr $suf / 256)
	suf=$(expr $suf % 256)
fi
ip="162.16.$beg.$suf"
tapname="tap$id"
MASK="/24"
ethernet="wlp0s20f3"

if ifconfig | grep $tapname > /dev/null;
then
    echo "$tapname interface is already up"
    export firecracker_id=$id
    exit 0
fi

ip a show $tapname
if [ $? ]
then
	echo "$tapname already exists"
	ip link del $tapname
else
	if ping -c 1 -s 0 $ip > /dev/null;
	then
		echo "$ip is currently already in use"
		echo "please use a different id"
		exit 1
	else
		echo "$ip is going to be used"
	fi
	
fi
if [ $# -ge 2 ];
then
	if ip a show $2 > /dev/null;
	then
		ethernet=$2
	fi
fi
echo "using $ethernet network interface"

if ip tuntap add $tapname mode tap;
then
	echo "$tapname added"
else
	echo "unable to add $tapname"
fi

ip addr add ${ip}${MASK} dev $tapname
ip link set $tapname up
if ifconfig | grep $tapname > /dev/null;
then
    echo "$tapname interface is up"
else
    echo "Failed to bring up $tapname interface"
    exit 1
fi
sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

iptables -t nat -A POSTROUTING -o $ethernet -j MASQUERADE
iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $tapname -o $ethernet -j ACCEPT
iptables -A INPUT -p tcp --dport 8090 -j ACCEPT
iptables -A INPUT -j DROP
iptables -A OUTPUT -p tcp --dport 8090 -j ACCEPT
iptables -A OUTPUT -j DROP
if [ $? ];
then
	echo "host network setup completed"
	export firecracker_id=$id
fi
