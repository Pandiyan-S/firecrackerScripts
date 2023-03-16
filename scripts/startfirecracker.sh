#!/bin/sh

if [ -v firecracker_id ];
then
  echo "$firecrackr_id is current id"
else
  echo "firecracker id was not set.\nplease run host network setup before running firecracker"
  exit 1
fi

id=$firecracker_id
config_file=/home/pandi-con1220/Firecracker/config/${id}.json
cp /home/pandi-con1220/Firecracker/alpineconfig.json $config_file
sed -i "s/<tap-name>/tap1/g" $config_file
rm -rf /tmp/firecracker.socket
/home/pandi-con1220/Firecracker/firecracker/build/cargo_target/x86_64-unknown-linux-musl/debug/firecracker --api-sock /tmp/firecracker.socket --config-file $config_file
