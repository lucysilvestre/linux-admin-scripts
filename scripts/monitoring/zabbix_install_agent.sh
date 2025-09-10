#!/bin/bash
# zabbix_install_agent.sh
# Description: It installs the Zabbix agent in the client servers
# Created by System Administrator Luciana Silvestre

# Prompt for user inputs
read -p "Enter the Internal IP of Zabbix Proxy: " ZABBIX_PROXY_IP
read -p "Enter the Hostname of this machine: " HOSTNAME

# Install the latest Zabbix repository
sudo rpm -Uvh https://repo.zabbix.com/zabbix/6.0/rhel/8/x86_64/zabbix-release-latest.el8.noarch.rpm

# Clean YUM cache
sudo yum clean all

# Install Zabbix Agent 2
sudo yum install -y zabbix-agent2

# Update the Zabbix Agent 2 configuration file
sudo sed -i "s/^Server=.*/Server=$ZABBIX_PROXY_IP/" /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^ServerActive=.*/ServerActive=$ZABBIX_PROXY_IP/" /etc/zabbix/zabbix_agent2.conf
sudo sed -i "s/^Hostname=.*/Hostname=$HOSTNAME/" /etc/zabbix/zabbix_agent2.conf

# Enable and start the Zabbix Agent 2 service
sudo systemctl enable --now zabbix-agent2

echo "Zabbix Agent 2 installation and configuration complete."
