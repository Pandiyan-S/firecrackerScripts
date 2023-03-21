#!/bin/sh

exitstate()
{
        if [ $1 -ne 0 ];
        then
                echo $2
                exit $1
        fi
}

if [ $# -eq 0 ];
then
	exitstate 1 "no id entered"
fi

VM_ID=$1

sudo /home/pandi-con1220/Firecracker/scripts/hostnetworksetup.sh $VM_ID
exitstate $? "host network setup failure"

CHROOT_BASE="/home/pandi-con1220/jail"
CHROOT_PATH="${CHROOT_BASE}/firecracker/$VM_ID/root"
firehome="/home/pandi-con1220/Firecracker/firecracker/build/cargo_target/x86_64-unknown-linux-musl/debug/"

sudo rm -rf $CHROOT_BASE/firecracker/$VM_ID
echo $?
mkdir -p $CHROOT_PATH

cp /home/pandi-con1220/Firecracker/firecracker/build/kernel/linux-4.14/vmlinux /home/pandi-con1220/Firecracker/rootfs /home/pandi-con1220/Firecracker/alpineconfig.json $CHROOT_PATH

echo $VM_ID
df | grep /tmp/rootfs
if [ $? -eq 0 ];
then
	sudo umount /tmp/my-rootfs
else
	mkdir /tmp/my-rootfs
fi
echo $?
sudo mount $CHROOT_PATH/rootfs /tmp/my-rootfs
echo $VM_ID
cat /tmp/my-rootfs/etc/init.d/my-node-app
sudo sed -i "s/<id-no>/$VM_ID/g" /tmp/my-rootfs/etc/init.d/my-node-app
cat /tmp/my-rootfs/etc/init.d/my-node-app
sudo umount /tmp/my-rootfs

sudo chmod 777 ${CHROOT_PATH}/*
echo $?
sed -i "s/<tap-name>/tap${VM_ID}/g" ${CHROOT_PATH}/alpineconfig.json

echo "${CHROOT_PATH}/alpineconfig.json"
$firehome/jailer --id $VM_ID --exec-file "$firehome/firecracker" --uid 618256567 --gid 618136065 --chroot-base-dir $CHROOT_BASE -- --config-file "alpineconfig.json"
