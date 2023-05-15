#!/bin/bash
#===================================================================================
# LABADMIN SCRIPT SERVER AGENT CONFIG
#         FILE: config
#  DESCRIPTION: Labadmin script server client agent config variables
#
#       AUTHOR: Leonardo Marco (labadmin@leonardomarco.com)
#      LICENSE: GNU General Public License v3.0
#      VERSION: 2022.06
#      CREATED: 28.06.2022
#=================================================================================== 

#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$log_path="${agent_path}\log.txt"									# File path where save logs
$repository="windows"												# Script repository name
$sshaddress="10.0.2.15"												# SSH IP address
$sshport="58889"													# SSH port
$sshuser="labadmin"													# SSH username
$sshcmd="/opt/labadmin-script_server/labadmin-script_server"		# Labadmin script server command path in remote server

# Local SSH agent key path for ssh authentication
# CAUTION: after install sample keys are used, pelase consider generate and copy your own keys
# By default first .pk file in agent install path, feel free to set direct path to your key
$sshprivatekey_path="${agent_path}\id_labadmin-agent_win.pk"

