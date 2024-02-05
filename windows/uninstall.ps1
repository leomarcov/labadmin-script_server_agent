#Requires -RunAsAdministrator

#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\labadmin-script_server_agent"
$agent_data="${ENV:ALLUSERSPROFILE}\labadmin\labadmin-script_server_agent"
$agent_file="${agent_path}\labadmin-script_server_agent.ps1"
$agent_user="labadmin"

#===============================================================================
#  CHECK CREDENTIALS
#===============================================================================
# Run as admin
if(!((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
	Write-Error "Must exec as Administrator"
	exit 1
}

#===============================================================================
#  DELETE LOCAL USER 
#===============================================================================
if ((Get-LocalUser -Name $agent_user -ErrorAction SilentlyContinue)) {
	Write-Host "`nDeleting local user $agent_path ..." -ForegroundColor Green
	Remove-LocalUser -Name $agent_user
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name "$agent_user" -Force
}


#===============================================================================
#  REMOVE SCHEDULE JOB
#===============================================================================
Write-Host "`nRemoving scheduled job..." -ForegroundColor Green
Unregister-ScheduledJob labadmin-script_server-agent -ErrorAction SilentlyContinue


#===============================================================================
#  REMOVE FILES
#===============================================================================
Write-Host "`nRemoving files on $agent_path and $agent_data ... -ForegroundColor Green
Remove-Item -Recurse -Force -Path $agent_data
Remove-Item -Recurse -Force -Path $agent_path
