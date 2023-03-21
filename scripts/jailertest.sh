#!/bin/sh

VM_ID=$1
id="1"
CHROOT_BASE="/home/pandi-con1220/jailer_test"
CHROOT_PATH="${CHROOT_BASE}/firecracker/$VM_ID/root"
firehome="/home/pandi-con1220/Firecracker/firecracker/build/cargo_target/x86_64-unknown-linux-musl/debug/"

sudo rm -rf $CHROOT_BASE/firecracker/$VM_ID
echo $?
mkdir -p $CHROOT_PATH

cp /home/pandi-con1220/Firecracker/firecracker/build/kernel/linux-4.14/vmlinux /home/pandi-con1220/Firecracker/rootfs /home/pandi-con1220/Firecracker/alpineconfig.json $CHROOT_PATH

sudo chmod 777 ${CHROOT_PATH}/*
echo $?
sed -i "s|<kernel-path>|vmlinux|g" ${CHROOT_PATH}/alpineconfig.json
sed -i "s|<rootfs-path>|rootfs|g" ${CHROOT_PATH}/alpineconfig.json
sed -i "s/<tap-name>/tap${id}/g" ${CHROOT_PATH}/alpineconfig.json

echo "${CHROOT_PATH}/alpineconfig.json"
$firehome/jailer --id $VM_ID --exec-file "$firehome/firecracker" --uid 618256567 --gid 618136065 --chroot-base-dir $CHROOT_BASE -- --config-file "alpineconfig.json"
