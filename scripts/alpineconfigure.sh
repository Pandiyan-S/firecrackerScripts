#!/bin/sh

apk add openssh
apk add nodejs 
apk add npm
apk add openrc
apk add util-linux

ln -s agetty /etc/init.d/agetty.ttyS0
echo ttyS0 > /etc/securetty
echo "root:root" | chpasswd 
echo $?
rc-update add agetty.ttyS0 boot
rc-update add devfs boot
rc-update add procfs boot
rc-update add sysfs boot
rc-update add 

for d in bin etc lib root sbin usr; do tar c "/$d" | tar x -C /my-rootfs; done
for dir in dev proc run sys var; do mkdir /my-rootfs/${dir}; done
exit
