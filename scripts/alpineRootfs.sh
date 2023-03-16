#!/bin/sh

dd if=/dev/zero of=rootfs.ext4 bs=1M count=500
mkfs.ext4 /home/pandi-con1220/Firecracker/rootfs.ext4
if [ $# -ne 0 ] && [ $1 != /tmp/my-rootfs/ ] && [ $1 != /tmp/my-rootfs ];
then
	mount=$1
	if [ -d $mount ];
	then
        	if [ "$(ls -A $mount)" ];
        	then
                	echo "$mount is not empty so creating a directory mnt in the given path"
                	mount="$(mount)/mnt/"
                	mkdir $mount
        	else
                	echo "$mount is an empty directory"
        	fi
	else
        	echo "$mount does not exist"
        	mkdir $mount
        	if [ $? -eq 0 ];
        	then
                	echo "$mount was successfully created"
		else
			echo "$mount could not be created"
			mount=/tmp/my-rootfs/
		fi
	fi
else
	mount=/tmp/my-rootfs/
	if [ ! -d $mount ];
	then
		mkdir $mount
	fi
	echo "default directory $mount"
fi

sudo mount rootfs.ext4 $mount
sudo cp /home/pandi-con1220/Firecracker/scripts/alpineconfigure.sh $mount
ls $mount
sudo chmod +x ${mount}/*
docker run --rm -v $mount:/my-rootfs alpine sh -c '/my-rootfs/alpineconfigure.sh'
sudo rm ${mount}/alpineconfigure.sh
echo $?
sudo cp /home/pandi-con1220/Firecracker/scripts/alpineguestsetup.sh $mount/root
ls $mount
echo $?
sudo umount $mount
echo $?
