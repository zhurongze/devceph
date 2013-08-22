#!/usr/bin/env bash

unset GREP_OPTIONS
TOP_DIR=$(cd $(dirname "$0") && pwd)
DATA_DIR=$TOP_DIR/data
CEPH_CONF=/etc/ceph/ceph.conf
HOST_INTERFACE=eth0
TEMP_CONF=/tmp/ceph.conf
JOURNAL_SIZE=100
REP_SIZE=2


function install_ceph() {    
    echo "### Check Environment"
    HOSTNAME=`hostname`
    if [ $HOSTNAME = "localhost" ]; then
        echo "WARN: You need to change hostname from 'localhost' to other"
        exit 1
    fi
    
    echo "### Install Release Key"
    wget -q -O- 'https://ceph.com/git/?p=ceph.git;a=blob_plain;f=keys/release.asc' | sudo apt-key add -
    
    echo "### Add Release Packages"
    echo deb http://ceph.com/debian-dumpling/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list

    echo "### Install Ceph Packages"
    sudo apt-get update && sudo apt-get install ceph uuid -y

    if [ ! -d $DATA_DIR ]; then
        sudo mkdir $DATA_DIR
    fi
    
    echo "### Cleanup Data Directory"
    sudo rm -rf $DATA_DIR/*

    echo "### Generate ceph.conf"
    generate_temp_conf
    if [ ! -d /etc/ceph ]; then
        sudo mkdir /etc/ceph
    fi
    sudo cp $TEMP_CONF $CEPH_CONF
    sudo mkdir -p $DATA_DIR/mon-a
    sudo mkdir -p $DATA_DIR/osd-0
    sudo mkdir -p $DATA_DIR/osd-1
    sudo mkdir -p $DATA_DIR/osd-2
    

    echo "### Initialize Ceph"
    sudo mkcephfs -a -c /etc/ceph/ceph.conf -k /etc/ceph/ceph.client.admin.keyring

    echo "### Install Over"
}

function generate_temp_conf() {

    HOST_IP=`LC_ALL=C ip -f inet addr show ${HOST_INTERFACE} | awk '/inet/ {split($2,parts,"/");  print parts[1]}'`
    HOST_NAME=`hostname`

    echo '' > $TEMP_CONF

    FSID=`uuid`
    OSD_DATA=$DATA_DIR/osd-'$id'
    OSD_JOURNAL=$OSD_DATA/journal
    MON_DATA=$DATA_DIR/mon-a
#    inset_ini_line $TEMP_CONF global fsid $FSID
#    inset_ini_line $TEMP_CONF global 'mon initial members' $HOST_NAME
#    inset_ini_line $TEMP_CONF global 'mon host' $HOST_IP
    inset_ini_line $TEMP_CONF global 'filestore xattr use omap' 'true'
    inset_ini_line $TEMP_CONF global 'auth supported' 'cephx'
    inset_ini_line $TEMP_CONF global 'osd crush chooseleaf type' 0
    inset_ini_line $TEMP_CONF global 'osd pool default size' $REP_SIZE
    inset_ini_line $TEMP_CONF global 'osd pool default pg num' 96
    inset_ini_line $TEMP_CONF global 'osd pool default pgp num' 96
    inset_ini_line $TEMP_CONF osd 'osd journal size' $JOURNAL_SIZE
    inset_ini_line $TEMP_CONF osd 'osd data' $OSD_DATA
    inset_ini_line $TEMP_CONF osd 'osd journal' $OSD_JOURNAL
    inset_ini_line $TEMP_CONF mon.a 'host' $HOST_NAME
    inset_ini_line $TEMP_CONF mon.a 'mon addr' $HOST_IP:6789
    inset_ini_line $TEMP_CONF mon.a 'mon data' $MON_DATA

    inset_ini_line $TEMP_CONF osd.0 'host' $HOST_NAME
    inset_ini_line $TEMP_CONF osd.1 'host' $HOST_NAME
    inset_ini_line $TEMP_CONF osd.2 'host' $HOST_NAME
}

function inset_ini_line() {
    local file=$1                                                              
    local section=$2                                                           
    local option=$3                                                            
    local value=$4                                                             
    if ! grep -q "^\[$section\]" "$file"; then                                 
        # Add section at the end                                               
        echo -e "\n[$section]" >>"$file"                                       
    fi 

    echo -e "$option = $value" >> "$file"
}

function clean_ceph() {
    stop_ceph

    echo "### Cleanup Data Directory"
    rm -rf $DATA_DIR/*

    echo "### Remove Ceph Conf"
    rm -f $CEPH_CONF
}

function uninstall_ceph() {
    clean_ceph

    echo "### Uninstall Ceph"
    sudo apt-get remove ceph -y
    
}

function stop_ceph() {
    echo "### Stop Ceph Service"
    sudo service ceph -a stop
}

function start_ceph() {
    echo "### Start Ceph Service"
    sudo service ceph -a start

    echo "### Seting Iptables"
    iptables -A INPUT -m multiport -p tcp -s 0.0.0.0/24 --dports 6789,6800:6900 -j ACCEPT

}

function restart_ceph() {
    stop_ceph
    start_ceph
}

if [ -z $1 ]; then
    echo "Usage: $0 install|uninstall|start|stop|restart"
    exit 1
fi

COMMAND=$1

case $COMMAND in
help)
    echo "Usage: $0 install|uninstall|start|stop|restart"
    ;;
install)
    install_ceph
    ;;
uninstall)
    uninstall_ceph
    ;;
start)
    start_ceph
    ;;
clean)
    clean_ceph
    ;;
stop)
    stop_ceph
    ;;
restart)
    restart_ceph
    ;;
*)
    echo "Error Command!!"
    echo "Usage: $0 install|uninstall|clean|start|stop|restart"
    exit 1
esac
