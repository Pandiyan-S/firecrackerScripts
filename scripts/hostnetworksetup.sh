#!/bin/sh

exitstate()
{
	if [ $1 -ne 0 ];
	then
		echo $2
		exit $1
	fi
}
iptablerules()
{
	sh -c "echo 1 > /proc/sys/net/ipv4/ip_forward"

	iptables -F
	iptables-restore < /home/pandi-con1220/iptables/baserules.v4

	iptables -t nat -A POSTROUTING -o $2 -j MASQUERADE
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i $1 -o $2 -j ACCEPT
	iptables -A INPUT -p tcp --dport 8090 -j ACCEPT
	iptables -A INPUT -j DROP
	iptables -A OUTPUT -p tcp --dport 8090 -j ACCEPT
	iptables -A OUTPUT -j DROP
}

tapcreate()
{
	MASK="/31"
	ip tuntap add $1 mode tap
	exitstate $? "unable to add $1"
	echo "$1 added"

	ip addr add ${2}${MASK} dev $1
	ip link set $1 up
	ifconfig | grep $1 > /dev/null
	exitstate $? "Failed to bring up $1 interface"
	echo "$1 interface is up"
}

ethernet="wlp0s20f3"
id=$1
beg=0
if [ $# -eq 0 ];
then
	exitstate 1 "ERROR : no id provided"
fi
if [ $1 -gt 32767 ] || [ $1 -lt 0 ];
then
	exitstate 1 "invalid id"
fi
if [ $# -ge 2 ];
then
	if ip a show $2 > /dev/null;
	then
		ethernet=$2
	fi
fi

echo "using $ethernet network interface"

suf=$(expr $id \* 2)
if [ "$suf" -gt 255 ];
then
	beg=$(expr $suf / 256)
	suf=$(expr $suf % 256)
fi
ip="162.16.$beg.$suf"
tapname="tap$id"

if ifconfig | grep $tapname > /dev/null;
then
    echo "$tapname interface is already up"
    iptablerules $tapname $ethernet
    exit 0
fi

echo "$tapname"
ip a show $tapname
if [ $? -eq 0 ];
then
	echo "$tapname already exists"
	ip tuntap del $tapname mode tap
else
	ping -c 1 -s 0 $ip > /dev/null
	if [ $? -eq 0 ];
	then
		exitstate 1 "$ip is currently already in use\nplease use a different id"
	fi
	echo "$ip is going to be used"
fi

tapcreate $tapname $ip

iptablerules $tapname $ethernet
if [ $? -eq 0 ];
then
	echo "host network setup completed"
	exit 0
fi
