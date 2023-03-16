#!/bin/sh

id=$(cat /root/firecracker_id)
echo $id
beg=0
hostsuf=$(expr $id \* 2)
if [ "$hostsuf" -gt 255 ];
then
        beg=$(expr $hostsuf / 256)
        hostsuf=$(expr $hostsuf % 256)
fi
echo $hostsuf
hostip="162.16.$beg.$hostsuf"
suf=$(expr $hostsuf + 1)
ip="162.16.$beg.$suf"
echo $ip
echo $hostip
ip addr add $ip/24 dev eth0
ip link set eth0 up
ip route add default via $hostip dev eth0
ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -N ""
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd
rc-service sshd restart
echo "finished network setup"
