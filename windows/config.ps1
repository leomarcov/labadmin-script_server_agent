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
$repository="windows"                                               # Server repository name to query scripts
$log_path="${agent_data}\log.txt"                                   # File path where save logs
$sshaddress="10.119.171.216"                                        # SSH IP address
$sshport="58889"                                                    # SSH port
$sshuser="lss-agent"                                                # SSH username

# Local SSH agent key path for ssh authentication
# CAUTION: after install sample keys are used, pelase consider generate and copy your own keys
# By default first .pk file in agent install path, feel free to set direct path to your key
$sshprivatekey_path="${agent_data}\id_lss-agent.pk"

