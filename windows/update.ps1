#Requires -RunAsAdministrator

#===================================================================================
# LABADMIN SCRIPT SERVER AGENT INSTALL FOR WINDOWS
#         FILE: update.ps1
#  DESCRIPTION: Labadmin script server client agent update for Windows hosts
#
#       AUTHOR: Leonardo Marco (labadmin@leonardomarco.com)
#	   LICENSE: GNU General Public License v3.0
#      VERSION: 2024.11
#      CREATED: 2022.06.28
#=================================================================================== 


#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\lss-agent"
$url="https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows"

Write-Host "`nDownloading script files ..." -ForegroundColor Green
Invoke-WebRequest -Uri ($url+"/lss-agent.ps1") -OutFile ($agent_path+"\lss-agent.ps1")
Invoke-WebRequest -Uri ($url+"/lss-config-schedule.ps1") -OutFile ($agent_path+"\lss-config-schedule.ps1")
Invoke-WebRequest -Uri ($url+"/version") -OutFile ($agent_path+"\version")
Invoke-WebRequest -Uri ($url+"/install.ps1") -OutFile ($agent_path+"\install.ps1")
Invoke-WebRequest -Uri ($url+"/uninstall.ps1") -OutFile ($agent_path+"\uninstall.ps1")
Invoke-WebRequest -Uri ($url+"/update.ps1") -OutFile ($agent_path+"\update.ps1")
