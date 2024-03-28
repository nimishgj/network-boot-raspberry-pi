#!/bin/bash

PORT=69
LOG_FILE_PATH="/var/log/macscript.log"
#echo "Checking if a MAC address is provided as an argument" >> $LOG_FILE_PATH
#if [ $# -ne 1 ]; then
#    echo "Usage: $0 <MAC_ADDRESS>" >> $LOG_FILE_PATH
#    exit 1
#fi

create_mac() {
    local mac_address="$1"

    echo "**********Running script for $mac_address**********" >> $LOG_FILE_PATH

    ####################################################################
    configure_dnsmasq() {
        local service_name="$1"

        if [ "$service_name" == "dnsmasq" ]; then
            if systemctl list-unit-files --type=service | grep -q "^dnsmasq.service"; then
                echo "Configuring dnsmasq.conf..."
                read -p "Enter the interface name (e.g., bond0): " interface_name
                cat <<EOF | sudo tee -a /etc/dnsmasq.conf > /dev/null
interface=$interface_name
no-hosts
log-dhcp
enable-tftp
tftp-root=/srv/tftp
tftp-unique-root=mac
log-facility=/var/log/dnsmasq
port=5353
EOF
                echo "Configuration has been added to /etc/dnsmasq.conf"  >> $LOG_FILE_PATH
            fi
        fi
    }

    check_service_installed() {
        local service_to_check="$1"

        if systemctl list-unit-files --type=service | grep -q "^$service_to_check.service"; then
            echo "$service_to_check is installed" >> $LOG_FILE_PATH
        else
            echo "$service_to_check is being installed" >> $LOG_FILE_PATH

            sudo apt update
            sudo apt install -y "$service_to_check"

            if [ $? -eq 0 ]; then
                echo "$service_to_check has been installed successfully." >> $LOG_FILE_PATH

                configure_dnsmasq "$service_to_check"
            else
                echo "Failed to install $service_to_check. Please check and install it manually." >> $LOG_FILE_PATH
            fi
        fi
    }

    check_service_installed "nfs-kernel-server"
    check_service_installed "dnsmasq"
    #####################################################################

    echo "Creating $mac_address directories for tftp and nfs" >> $LOG_FILE_PATH

    sudo mkdir -p /srv/tftp/$mac_address
    sudo mkdir -p /srv/nfs/$mac_address

    echo "Copying rootfiles to  nfs/$mac_address" >> $LOG_FILE_PATH
    sudo cp -a /home/odroid/userfiles/* /srv/nfs/$mac_address
    echo "Finished copying rootfiles" >> $LOG_FILE_PATH

    echo "Copying bootfiles to tftp/$mac_address" >> $LOG_FILE_PATH
    sudo cp -r /home/odroid/bootfiles/* /srv/tftp/$mac_address
    echo "Finished copying bootfiles" >> $LOG_FILE_PATH

    echo "Replacing contents of cmdline.txt" >> $LOG_FILE_PATH

    echo  -e "console=serial0,115200 console=tty1 root=/dev/nfs nfsroot=192.168.88.100:/srv/nfs/$mac_address rw rootwait" | sudo tee /srv/tftp/$mac_address/cmdline.txt > /dev/null

    new_content="proc            /proc           proc    defaults          0       0\n\
    PARTUUID=4e639091-02  /               ext4    defaults,noatime  0       1\n\
    192.168.88.100:/srv/tftp/$mac_address /boot nfs defaults 0 0"

    echo "Replacing contents of fstab" >> $LOG_FILE_PATH

    echo -e "$new_content" | sudo tee /srv/nfs/$mac_address/etc/fstab > /dev/null

    echo "Adding nfs entry in /etc/exports" >> $LOG_FILE_PATH

    echo "/srv/nfs/$mac_address *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports >/dev/null

    echo "Adding tftp entry in /etc/exports" >> $LOG_FILE_PATH

    echo "/srv/tftp/$mac_address *(rw,sync,no_subtree_check,no_root_squash)" | sudo tee -a /etc/exports >/dev/null

    echo "Running exportfs" >> $LOG_FILE_PATH

    sudo exportfs -r

    echo "**********Successfully completed execution for $mac_address**********" >> $LOG_FILE_PATH
}

# Function to handle errors
handle_error() {
    echo "An error occurred at line $1" >> $LOG_FILE_PATH
    exit 1
}

# Set up trap to catch errors and execute handle_error function
trap 'handle_error $LINENO' ERR

tcpdump -l -i any -e udp port $PORT | while read line; do
    MAC=$(echo $line | awk '{print $6}' | tr ':' '-')
    TIME=$(date +"%Y-%m-%d %H:%M:%S")

    # Check if the MAC address is already in the addresslist.txt file
    if grep -q "$MAC" /opt/addresslist.txt; then
        echo "$MAC already exists" >> $LOG_FILE_PATH
    else
        echo "************Executing macscript.sh for $MAC***************" >> $LOG_FILE_PATH
        echo "$MAC" >> /opt/addresslist.txt

        FILE=$(echo $line | grep -o -P '(?<=RRQ ")[^"]+')

        # Filter out the file name and exclude any parent dirs
        FILE=$(awk -F'/' '{print $NF}' <<< "$FILE")

        if [ "$FILE" = "start4.elf" ]; then
            echo "Time: $TIME, MAC address: $MAC, Requested file: $FILE" >> $LOG_FILE_PATH
            #sudo systemctl stop dnsmasq > /dev/null
            #sudo systemctl stop nfs-kernel-server > /dev/null
            create_mac "$MAC" &
            #sudo systemctl start dnsmasq > /dev/null
            #sudo systemctl start nfs-kernel-server.service > /dev/null
            echo "**********macscript execution finished for mac $MAC**********" >> $LOG_FILE_PATH
        else
            echo "Not found" >> $LOG_FILE_PATH
        fi
    fi
done
