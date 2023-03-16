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

	iptables -t nat -A POSTROUTING -o $2 -j MASQUERADE
	iptables -A FORWARD -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	iptables -A FORWARD -i $1 -o $2 -j ACCEPT
	iptables -A INPUT -p tcp --dport 8090 -j ACCEPT
	iptables -A INPUT -j DROP
	iptables -A OUTPUT -p tcp --dport 8090 -j ACCEPT
	iptables -A OUTPUT -j DROP
}

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
echo $?

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
    iptablerules $tapname $ethernet
    echo "$id" > /home/pandi-con1220/Firecracker/scripts/firecracker_id
    exit 0
fi

ip a show $tapname
if [ $? ]
then
	echo "$tapname already exists"
else
	ping -c 1 -s 0 $ip > /dev/null
	exitstate $? "$ip is currently already in use\nplease use a different id"
	echo "$ip is going to be used"
	ip tuntap add $tapname mode tap
	exitstate $? "unable to add $tapname"
	echo "$tapname added"
fi

ip addr add ${ip}${MASK} dev $tapname
ip link set $tapname up
ifconfig | grep $tapname > /dev/null
exitstate $? "Failed to bring up $tapname interface"
echo "$tapname interface is up"

iptablerules $tapname $ethernet
if [ $? ];
then
	echo "host network setup completed"
	echo "$id" > /home/pandi-con1220/Firecracker/scripts/firecracker_id
fi
