#!/usr/bin/env bash

DATA_DISK=/dev/xvdb

# Print specified message to STDOUT with timestamp prefix.
function log() {
    echo "****************** $msg ******************"
}

function install_dependencies() {
	log "install_dependencies()"

	# update existing packages
	sudo yum -y update

	# install prerequisite packages
	sudo yum -y install deltarpm
	#sudo yum -y install openssl net-snmp net-snmp-utils cyrus-sasl cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain xfsprogs xfsdump
	sudo yum -y install xfsprogs xfsdump
}

function configure_data_volume() {
	log "configure_data_volume()"

	# apply XFS filesystem to EBS disk and create /data directory
	sudo mkfs -t xfs $DATA_DISK
	sudo mkdir /data
	
	# set readahead to 0
	sudo blockdev --setra 0 $DATA_DISK
	echo "ACTION==\"add|change\", KERNEL==\"$DATA_DISK\", ATTR{bdi/read_ahead_kb}=\"0\"" | sudo tee -a /etc/udev/rules.d/85-ebs.rules

	# add device to /etc/fstab and mount
	sudo cp /etc/fstab /etc/fstab.orig
	UUID=`sudo xfs_admin -u $DATA_DISK | cut -d' ' -f3`
	echo "UUID=$UUID       /data   xfs    defaults,nofail,noatime,noexec        0       2" | sudo tee -a /etc/fstab
	sudo mount -a
}

function install_and_configure_mongod(){
	log "install_and_configure_mongod()"
	
	# install mongod
	sudo cp /tmp/scripts/mongodb-enterprise.repo /etc/yum.repos.d
	sudo yum install -y mongodb-enterprise
	sudo chkconfig mongod on
	
	# configure mongod.conf
	sudo cp /tmp/config/mongod.conf /etc/mongod.conf
	#sudo sed -i -e 's/dbPath:.*/dbPath: \/data/g' /etc/mongod.conf
	#sudo sed -i -e 's/bindIp:.*/bindIp: 0.0.0.0/g' /etc/mongod.conf
	
	# set ownership of data volume
	sudo chown mongod: /data

	# start service
	sudo service mongod start	
}

function disable_thp() {
	log "disable_thp()"
	sudo mv /tmp/scripts/disable-transparent-hugepages /etc/init.d
	sudo chmod 755 /etc/init.d/disable-transparent-hugepages
	sudo chkconfig --add disable-transparent-hugepages
	sudo service start disable-transparent-hugepages
}

function install_and_configure_mms_agent() {
	log "install_and_configure_mms_agent()"
}

# handled by RPM - ignore
function configure_ulimits() {
	sudo mv /tmp/scripts/99-mongodb-nproc.conf /etc/security/limits.d
}

log "Starting MongoDB provisioning"

install_dependencies
configure_data_volume
disable_thp
install_and_configure_mongod