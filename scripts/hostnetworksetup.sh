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

#	iptables -F
#	iptables-restore < /home/pandi-con1220/iptables/baserules.v4
	
	iptables -t nat -A PREROUTING -p tcp -i $2 --dport $4 -j DNAT --to-destination $3:8090
	echo $4
	echo $3
#	iptables -t nat -A POSTROUTING -o $1 -p tcp --dport $4 -d $3 -j SNAT --to-source $5:$4
	iptables -C FORWARD -o $2 -j ACCEPT
	if [ $? -ne 0 ];
	then
		iptables -I FORWARD 3 -o $2 -j ACCEPT
	fi
	iptables -C FORWARD -i $2 -j ACCEPT
	if [ $? -ne 0 ];
	then
		iptables -I FORWARD 4 -i $2 -j ACCEPT
	fi
	iptables -C FORWARD -i $1 -o $2 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	if [ $? -ne 0 ];
	then
		iptables -A FORWARD -i $1 -o $2 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	fi
	iptables -C FORWARD -i $2 -o $1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	if [ $? -ne 0 ];
	then
		iptables -A FORWARD -i $2 -o $1 -m conntrack --ctstate RELATED,ESTABLISHED -j ACCEPT
	fi

#	sudo iptables -I FORWARD 5 -i wlp0s20f3 -j ACCEPT
#	sudo iptables -I FORWARD 5 -o wlp0s20f3 -j ACCEPT
#	
	
#	iptables -A INPUT -p tcp --dport 8090 -j ACCEPT
#	iptables -A OUTPUT -p tcp --sport 8090 -j ACCEPT
#	iptables -A OUTPUT -p tcp --dport 8090 -j ACCEPT
#	iptables -A INPUT -p tcp --sport 8090 -j ACCEPT
#	iptables -A INPUT -j DROP
#	iptables -A OUTPUT -j DROP
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



if [ $# -eq 0 ];
then
	exitstate 1 "ERROR : no id provided"
fi
case $1 in
	*[!0-9]*)
		exitstate 1 "invalid arguements"
		;;
	*)
		echo "valid argument "
		;;
esac
if [ $1 -gt 32767 ] || [ $1 -lt 0 ];
then
	exitstate 1 "invalid id"
fi

ethernet="wlp0s20f3"
id=$1
hostport=$(expr $id + 8090)
beg=0
internet="false"

shift
for var in "$@"
do
case "$var" in
    "--internet"*)
        internet="true"
        ;;
    *)
        echo "Invalid Option $var"
        ;;
esac
done

echo "using $ethernet network interface"

hostsuf=$(expr $id \* 2)
if [ "$hostsuf" -gt 255 ];
then
	beg=$(expr $hostsuf / 256)
        hostsuf=$(expr $hostsuf % 256)
fi
echo $hostsuf
hostip="162.16.$beg.$hostsuf"
guestsuf=$(expr $hostsuf + 1)
guestip="162.16.$beg.$guestsuf"
tapname="tap$id"

if ifconfig | grep $tapname > /dev/null;
then
	echo "$tapname interface is already up"
	iptablerules $tapname $ethernet $guestip $hostport
	iptables -t nat -D POSTROUTING -s $guestip -o $ethernet -j MASQUERADE > /dev/null 2>&1
	if [ "$internet" = "true" ];
	then
		iptables -t nat -A POSTROUTING -s $guestip -o $ethernet -j MASQUERADE
	fi
	exit 0
fi

echo "$tapname"
ip a show $tapname
if [ $? -eq 0 ];
then
	echo "$tapname already exists"
	ip tuntap del $tapname mode tap
else
	ping -c 1 -s 0 $hostip > /dev/null
	if [ $? -eq 0 ];
	then
		exitstate 1 "$hostip is currently already in use\nplease use a different id"
	fi
	echo "$hostip is going to be used"
fi

tapcreate $tapname $hostip

iptablerules $tapname $ethernet $guestip $hostport
iptables -t nat -D POSTROUTING -s $guestip -o $ethernet -j MASQUERADE > /dev/null 2>&1
if [ "$internet" = "true" ];
then
	iptables -t nat -A POSTROUTING -s $guestip -o $ethernet -j MASQUERADE
fi

if [ $? -eq 0 ];
then
	echo "host network setup completed"
	exit 0
fi
