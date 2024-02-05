#Requires -RunAsAdministrator

#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\labadmin-script_server_agent"

$url="https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows"
Write-Host "`nUpdating $agent_path+"\labadmin-script_server_agent.ps1" -ForegroundColor Green
Invoke-WebRequest -Uri ($url+"/labadmin-script_server_agent.ps1") -OutFile ($agent_path+"\labadmin-script_server_agent.ps1")
Write-Host "`nUpdating $agent_path+"\install.ps1" -ForegroundColor Green
Invoke-WebRequest -Uri ($url+"/install.ps1") -OutFile ($agent_path+"\install.ps1")
Write-Host "`nUpdating $agent_path+"\uninstall.ps1" -ForegroundColor Green
Invoke-WebRequest -Uri ($url+"/uninstall.ps1") -OutFile ($agent_path+"\uninstall.ps1")
Write-Host "`nUpdating $agent_path+"\update.ps1" -ForegroundColor Green
Invoke-WebRequest -Uri ($url+"/update.ps1") -OutFile ($agent_path+"\update.ps1")
