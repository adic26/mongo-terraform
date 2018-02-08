# Library of utility and helper functions for sourcing.

CACHE_DIR=/vagrant/cache

# -----------------------------------------------------------------------------
# General helpers
# -----------------------------------------------------------------------------

# Print specified message to STDOUT with timestamp prefix.
function log() {
    local msg=$1
    local opts=$2
    local time=`date +%H:%M:%S`
    echo $opts "$time $msg"
}

function http_post() {
    local url=$1;  shift
    local method=$1; shift
    local data=$1; shift || true
    local args=()

    args=("${args[@]}" "-b $COOKIE -c $COOKIE")
    if [[ ! -z "$CSRF_TOKEN" ]] && [[ ! -z "$CSRF_TIME" ]]; then
        args=("${args[@]}" "--header X-CSRF-Token:$CSRF_TOKEN" "--header X-CSRF-Time:$CSRF_TIME" "--header X-Requested-With:XMLHttpRequest")
    fi
    if [[ ! -z "$data" ]]; then
        args=("${args[@]}" "--data "$data"")
    fi
    if [[ ! -z "$method" ]]; then
        args=("${args[@]}" "-X "$method"")
    fi

    cd $TMP_DIR
    curl -sS ${args[@]} $* "$url" 2>&1 > $TMP_DIR/curl.html
    cd - > /dev/null
}

function http_post_json() {
    local url=$1;  shift
    local data=$1; shift || true
    http_post "$url" POST "$data" --header Content-Type:application/json $*
}

function http_patch_json() {
    local url=$1;  shift
    local data=$1; shift || true
    http_post "$url" PATCH "$data" --header Content-Type:application/json $*
}

function get_token() {
    local url=$1
    local file=$TMP_DIR/token

    curl -sS -b $COOKIE -c $COOKIE $url > $file

    CSRF_TOKEN=`cat $file | grep csrf-token | sed -E 's/^.*content="([0-9a-z]+)".*$/\1/'`
    CSRF_TIME=`cat $file | grep csrf-time | sed -E 's/^.*content="([0-9a-z]*)".*$/\1/'`
}

# Parse command line options and sets corresponding global option variables.
function parse_opts() {
    log "** parse_opts()"
    while [[ $# > 0 ]]; do
        key="$1"
        shift
        case $key in
            --ssl)    SSL=true
                      log "   - SSL MODE";;
            --ldap)   LDAP=true
                      log "   - LDAP MODE";;
            --debug)  DEBUG=true
                      log "   - DEBUG MODE"
                      set -x;;
            *)        log "Unknown option: $key"
                      exit 1;;
        esac
    done
}

# -----------------------------------------------------------------------------
# Installation helpers
# -----------------------------------------------------------------------------

function import_rpm_gpg_keys() {
    log "** import_rpm_gpg_keys()"
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

    download RPM-GPG-KEY-EPEL-7 https://dl.fedoraproject.org/pub/epel/RPM-GPG-KEY-EPEL-7
    cp $CACHE_DIR/RPM-GPG-KEY-EPEL-7 /etc/pki/rpm-gpg/
    rpm --import /etc/pki/rpm-gpg/RPM-GPG-KEY-EPEL-7
}

# Cache RPMs for offline access
function enable_yum_cache() {
    log "** enable_yum_cache()"
    sed -i s/keepcache=0/keepcache=1/ /etc/yum.conf
    rm -rf /var/cache/yum
    ln -s /{vagrant,var}/cache/yum
    mkdir -p /vagrant/cache/yum/x86_64
}

# Prints 0 if an Internet connection is detected.
function has_internet() {
    echo `ping -W1 -c1 8.8.8.8 &>/dev/null; echo $?`
}

function install_package() {
    if [ -z "$YUM_OPTS" ]; then
        if [ `has_internet` -eq 0 ]; then
            YUM_OPTS=' '
        else
            log "** No Internet connection detected, using yum cache"
            YUM_OPTS='-C'
        fi
    fi
    yum install -y -q $YUM_OPTS $*
}

# Still need this for caching the Ops Manager RPMs - yum doesn't cache RPMs
# from URL or filesystem.
function download() {
    local file=$1
    local url=$2
    local ext="${file##*.}"

    cd $CACHE_DIR
    if [ -f $file ] && \
         ( ([ "$ext"  = "rpm" ] && rpm -K --nosignature --quiet $file >/dev/null 2>&1) || \
            [ "$ext" != "rpm" ] ); then
        log "Using cached $file"
    else
        log "Downloading $file..."
        rm -f $file
        curl -sS -LO $url
    fi
    cd - > /dev/null
}

function setup_ntp() {
    log "** setup_ntp()"
    install_package ntp
    systemctl start ntpd.service
    systemctl enable ntpd.service
}

function configure_hosts() {
    log "** configure_hosts()"
    cat >> /etc/hosts <<EOF
192.168.14.100   opsmgr.vagrant.dev opsmgr
192.168.14.101    node1.vagrant.dev node1
192.168.14.102    node2.vagrant.dev node2
192.168.14.103    node3.vagrant.dev node3
EOF
}

function install_enterprise_deps() {
    log "** install_enterprise_deps()"
    install_package deltarpm
    install_package openssl net-snmp net-snmp-utils cyrus-sasl cyrus-sasl-devel cyrus-sasl-gssapi cyrus-sasl-plain
}

function run_plugins() {
    local dir=$1
    _run_plugins /vagrant/provision.d
    _run_plugins /vagrant/provision-$dir.d
}

function _run_plugins() {
    local dir=$1
    log "** _run_plugins($dir)"
    for file in `ls $dir/*.sh 2>/dev/null`; do
        log "   Running plugin `basename $file`..."
        . $file
    done
}

# -----------------------------------------------------------------------------
# MongoDB helpers
# -----------------------------------------------------------------------------

# Wait for MongoDB to accept commands on the specified port.
function wait_mongod() {
    local port=$1
    local count=0
    log "** wait_mongod(): Waiting for MongoDB on port $port..."
    while true; do
        count=`mongo_eval $port 'printjson(db.runCommand("ping"))' 2>/dev/null | grep '{ "ok" : 1 }' | wc -l`
        [ $count -eq 1 ] && break
        sleep 1
    done
}

# Helper for running Javascript snippets in MongoDB.
function mongo_eval() {
    local port=$1
    local cmd=$2
    mongo --quiet --port $port --eval "$cmd"
}

# Needed to avoid "java.lang.OutOfMemoryError: unable to create new native
# thread" errors when starting MMS.
function configure_ulimit() {
    log "** configure_ulimit()"
    cp /vagrant/etc/99-mongodb-nproc.conf /etc/security/limits.d/
}

function configure_tuned() {
    log "** configure_tuned()"
    cp -a /usr/lib/tuned/virtual-guest{,-mongodb}
    cat /vagrant/etc/tuned/tuned.conf.append >> /usr/lib/tuned/virtual-guest-mongodb/tuned.conf
    cp  /vagrant/etc/tuned/script.sh /usr/lib/tuned/virtual-guest-mongodb/
    tuned-adm profile virtual-guest-mongodb
}

function update_os() {
    yum -y update
}

function base_setup() {
    log "** base_setup()"
    configure_hosts
    enable_yum_cache
    import_rpm_gpg_keys
    update_os
}

function base_setup_post_plugins() {
    log "** base_setup_post_plugins()"
    configure_ulimit
    configure_tuned
    setup_ntp
    install_enterprise_deps
}
