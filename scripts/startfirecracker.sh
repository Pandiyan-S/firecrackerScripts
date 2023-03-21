#!/bin/sh


exitstate()
{
	if [ $1 -ne 0 ];
	then
		echo $2
		exit $1
	fi
}

id=$1
sudo /home/pandi-con1220/Firecracker/scripts/hostnetworksetup.sh $id
exitstate $? "host network setup failure"

root="/home/pandi-con1220/Firecracker/alpineroot/root${id}"
kernel="/home/pandi-con1220/Firecracker/firecracker/build/kernel/linux-4.14/vmlinux"
if [ -e $root ];
then
	echo "rootfs already exists"
else
	cp /home/pandi-con1220/Firecracker/rootfs $root
	echo $id
	df | grep /tmp/rootfs
	if [ $? -eq 0 ];
	then
		sudo umount /tmp/my-rootfs
	else
		mkdir /tmp/my-rootfs
	fi
	sudo mount $root /tmp/my-rootfs
	sudo sed -i "s/<id-no>/${id}/g" /tmp/my-rootfs/etc/init.d/my-node-app
	sudo umount /tmp/my-rootfs
fi
config_file="/home/pandi-con1220/Firecracker/config/${id}.json"
cp /home/pandi-con1220/Firecracker/alpineconfig.json $config_file
echo $?
sed -i "s/<tap-name>/tap${id}/g" $config_file
sed -i "s|<kernel-path>|${kernel}|g" $config_file
echo "hi"
sed -i "s|<rootfs-path>|${root}|g" $config_file
rm -rf /tmp/firecracker.socket
/home/pandi-con1220/Firecracker/firecracker/build/cargo_target/x86_64-unknown-linux-musl/debug/firecracker --no-api --config-file $config_file
