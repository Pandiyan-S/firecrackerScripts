#!/bin/sh

ip addr add 162.16.0.1/24 dev eth0
ip link set eth0 up
ip route add default via 162.16.0.2 dev eth0
ssh-keygen -t rsa -q -f "$HOME/.ssh/id_rsa" -N ""
sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config
rc-service sshd restart
echo "finished network setup"
