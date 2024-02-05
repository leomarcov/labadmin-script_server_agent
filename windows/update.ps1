#Requires -RunAsAdministrator

#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\labadmin-script_server_agent"

Write-Host "`nDownloading script files ..." -ForegroundColor Green
$url="https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows"
Invoke-WebRequest -Uri ($url+"/labadmin-script_server_agent.ps1") -OutFile ($agent_path+"\labadmin-script_server_agent.ps1")
Invoke-WebRequest -Uri ($url+"/install.ps1") -OutFile ($agent_path+"\install.ps1")
Invoke-WebRequest -Uri ($url+"/uninstall.ps1") -OutFile ($agent_path+"\uninstall.ps1")
Invoke-WebRequest -Uri ($url+"/update.ps1") -OutFile ($agent_path+"\update.ps1")
