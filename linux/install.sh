#!/bin/bash
#===================================================================================
# LABADMIN SCRIPT SERVER AGENT INSTALL
#         FILE: labadmin-script_server_agent
#
#  DESCRIPTION: Labadmin script server client agent
#
#       AUTHOR: Leonardo Marco (labadmin@leonardomarco.com)
#      LICENSE: GNU General Public License v3.0
#      VERSION: 2022.06
#      CREATED: 28.06.2022
#=================================================================================== 

#===============================================================================
#  GLOBAL VARIABLES
#===============================================================================
readonly install_src="$(dirname "$(readlink -f "$0")")"
readonly install_dest="/opt/labadmin-script_server/linux_agent/"



#===============================================================================
#  AGENT INSTALL
#===============================================================================

# COPY FILES
if [ $(realpath "$install_path") != $(realpath "$install_dest") ]; then
	echo -e "\e[1mCopying files to "$install_dest"\e[0m"
	[ ! -d "$install_dest" ] && mkdir -vp "$install_dest" 
	chmod 700 "$install_path"
	cp -vr "${install_src}/"* "$install_path/"
fi

# CREATING SERVICE
echo -e "\e[1mCreating systemd service\e[0m"
echo '[Unit]
Description=Labadmin Script Server Agent
After=network.target
 
[Service]
Type=simple
ExecStart='"$install_path"'
Restart=on-failure
StandardOutput=journal
StandardError=jorunal
 
[Install]
WantedBy=multi-user.target' > /etc/systemd/system/labadmin-script_server_agent.service

systemctl daemon-reload
systemctl enable labadmin-script_server_agent.service
systemctl start labadmin-script_server_agent.service

# CONFIG FILES
echo -e "\e[1mEdit config files\e[0m"
echo "Please, to complete installation edit $install_dest/config file"
echo "and edit variables to config parameters"
