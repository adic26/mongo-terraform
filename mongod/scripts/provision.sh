#!/usr/bin/env bash

# Print specified message to STDOUT with timestamp prefix.
function log() {
    local msg=$1
    local opts=$2
    local time=`date +%H:%M:%S`
    echo $opts "$time $msg"
}

function install_dependencies() {
	log "** install_dependencies()"

	# update existing packages
	sudo yum -y update

	# install prerequisite packages
	sudo yum -y install deltarpm
	sudo yum -y install openssl net-snmp net-snmp-utils cyrus-sasl cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain xfsprogs xfsdump
}

function mount_xfs_volume() {
	log "** mount_xfs_volume()"

	# apply XFS filesystem to EBS disk and mount to /data
	sudo mkfs -t xfs /dev/xvdb
	sudo mkdir /data
	#sudo mount /dev/xvdb /data

	# add device to /etc/fstab
	sudo cp /etc/fstab /etc/fstab.orig
	UUID=`ls -l /dev/disk/by-uuid | grep "xvdb" | sed -n 's/^.* \([^ ]*\) -> .*$/\1/p'`
	echo "UUID=$UUID       /data   ext4    defaults,nofail        0       2" | sudo tee -a /etc/fstab
	sudo mount -a
}

echo "Starting MongoDB provisioning"

install_dependencies
mount_xfs_volume