#!/usr/bin/env bash

DATA_DISK=/dev/xvdb
MMS_VERSION=3.6.3.606

# Print specified message to STDOUT with timestamp prefix.
function log() {
    echo "****************** $1 ******************"
}

function install_dependencies() {
	log "installing dependencies"

	# update existing packages
	sudo yum -y -q update

	# install prerequisite packages
	sudo yum -y -q install deltarpm
	#sudo yum -y install openssl net-snmp net-snmp-utils cyrus-sasl cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain xfsprogs xfsdump
	sudo yum -y -q install xfsprogs xfsdump
}

function configure_data_volume() {
	if [ ! -d "/data" ]; then
		log "configuring data volume"
		
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
	fi
}

function install_mongod() {
	if [ ! -f "/etc/init.d/mongod" ]; then
		log "installing mongod"
		
		# install mongod
		sudo cp /tmp/scripts/mongodb-enterprise.repo /etc/yum.repos.d
		sudo yum install -y -q mongodb-enterprise
		sudo chkconfig mongod on
		
		# configure mongod.conf
		sudo cp /tmp/config/mongod.conf /etc/mongod.conf
		#sudo sed -i -e 's/dbPath:.*/dbPath: \/data/g' /etc/mongod.conf
		#sudo sed -i -e 's/bindIp:.*/bindIp: 0.0.0.0/g' /etc/mongod.conf
		
		# set ownership of data volume
		sudo chown mongod: /data

		# start service
		sudo service mongod start	
	fi
}

function install_mms() {
	if [ ! -f "/etc/init.d/mongodb-mms" ]; then
		log "installing Ops Mgr"
		
		local base_url=https://downloads.mongodb.com/on-prem-mms/rpm
        local mms_server=mongodb-mms-$MMS_VERSION-1.x86_64.rpm
    
		# download RPM
        curl -Lo /tmp/$mms_server $base_url/$mms_server

		# install ops manager
		sudo rpm -ivh $mms_server 

		# start on reboot
		sudo chkconfig mongodb-mms on
		
		# start service
		sudo service mongodb-mms start
	fi
}

function disable_thp() {
	if [ ! -f "/etc/init.d/disable-transparent-hugepages" ]; then
		log "disabling thp"
		sudo mv /tmp/scripts/disable-transparent-hugepages /etc/init.d
		sudo chmod 755 /etc/init.d/disable-transparent-hugepages
		sudo chkconfig --add disable-transparent-hugepages
		sudo service disable-transparent-hugepages start
	fi
}

function install_agent() {
	log "installing automation agent"
}

# handled by RPM - ignore
function configure_ulimits() {
	sudo mv /tmp/scripts/99-mongodb-nproc.conf /etc/security/limits.d
}

log "Starting MongoDB provisioning"

install_dependencies
configure_data_volume
disable_thp

for arg in "$@"
do
	case $arg in
		mongod) install_mongod;;
		mms)    install_mms;;
		agent)  install_agent;;
		*)        log "Unknown option: $arg"
				  exit 1;;
	esac
done