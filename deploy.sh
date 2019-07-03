#!/usr/bin/env bash

# Web Stack Deployment
# Copyright (c) 2019, aidanthewiz

# Exit if the script is not being run as root and output to stderr.
if [[ $EUID -ne 0 ]] || [[ $(id -u) -ne 0 ]]; then
   echo "This deploy script must be run as root 'sudo ./deploy.sh'" >&2
   exit 1
fi

# Update and Full Upgrade before configuration
apt update
apt full-upgrade -y

# Ask to enable firewall and allow OpenSSH
echo "Would you like to enable ufw (firewall) and allow OpenSSH?"
select yn in "Yes" "No"; do
    case $yn in
    Yes)
        ufw enable
        ufw allow OpenSSH
        break
    ;;
    No)
        break
    ;;
    esac
done

# Ask to change hostname
echo "Would you like to change your hostname (input will be trimmed for white space)?"
select yn in "Yes" "No"; do
    case $yn in
    Yes)
        echo "What would you like it set to?"
        read new_hostname
        # Preform trim on input
        read -rd '' new_hostname <<< "{$new_hostname}"
        hostnamectl set-hostname $new_hostname
        break
    ;;
    No)
        break
    ;;
    esac
done

