#Requires -RunAsAdministrator

#===================================================================================
# LABADMIN SCRIPT SERVER AGENT INSTALL FOR WINDOWS
#         FILE: uninstall.ps1
#  DESCRIPTION: Labadmin script server client agent uninstall for Windows hosts
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
$agent_data="${ENV:ALLUSERSPROFILE}\labadmin\lss-agent"
$agent_file="${agent_path}\lss-agent.ps1"
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
#  REMOVE SCHEDULE JOB
#===============================================================================
Write-Host "`nRemoving scheduled job..." -ForegroundColor Green
Start-Process powershell -ArgumentList "-File `"${agent_path}\lss-config-schedule.ps1`" -unregister"

#===============================================================================
#  DELETE LOCAL USER 
#===============================================================================
if ((Get-LocalUser -Name $agent_user -ErrorAction SilentlyContinue)) {
	Write-Host "`nDeleting local user $agent_path ..." -ForegroundColor Green
	$localuser = Get-LocalUser -Name $agent_user
	$localuser | Remove-LocalUser
	$userprofile = Get-CimInstance -Class Win32_UserProfile | Where-Object { $_.SID -eq $localuser.SID }
	$userprofile | Remove-CimInstance
	Remove-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList" -Name "$agent_user" -Force
}


#===============================================================================
#  REMOVE FILES
#===============================================================================
Write-Host "`nRemoving files on $agent_path and $agent_data ..." -ForegroundColor Green
$pk_file=$agent_data+"\id_lss-agent.pk"
$acl=Get-Acl $pk_file
$acl.SetAccessRuleProtection($true, $false)
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
$adminsgrp_name=(New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([type]'System.Security.Principal.NTAccount').value
$acl.SetOwner((New-Object System.Security.Principal.Ntaccount($adminsgrp_name)))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminsgrp_name, "FullControl", "Allow")))
Set-Acl -Path $pk_file -AclObject $acl

Remove-Item -Recurse -Force -Path $agent_data
Remove-Item -Recurse -Force -Path $agent_path
