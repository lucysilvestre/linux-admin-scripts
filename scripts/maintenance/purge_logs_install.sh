#!/bin/bash

# Script Created by System Administrator Luciana Silvestre - 2024-04-04
# purgelogs_ol7_setup.sh
# Description: This script install the Purgelog


# Path to the Purgelog RPM
rpm_path="/dbadmin/software/rpms/purgelogs-2.0.1-10.el7.x86_64.rpm"

# Install Purgelog
yum install "$rpm_path" -y
