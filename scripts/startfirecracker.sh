#!/bin/sh

root=/home/pandi-con1220/Firecracker/rootfs
fireid=/home/pandi-con1220/Firecracker/scripts/firecracker_id
id=$(cat $fireid)
sudo mount $root /tmp/my-rootfs
sudo cp $fireid /tmp/my-rootfs/root/
sudo umount /tmp/my-rootfs
config_file=/home/pandi-con1220/Firecracker/config/${id}.json
cp /home/pandi-con1220/Firecracker/alpineconfig.json $config_file
sed -i "s/<tap-name>/tap1/g" $config_file
rm -rf /tmp/firecracker.socket
/home/pandi-con1220/Firecracker/firecracker/build/cargo_target/x86_64-unknown-linux-musl/debug/firecracker --api-sock /tmp/firecracker.socket --config-file $config_file
