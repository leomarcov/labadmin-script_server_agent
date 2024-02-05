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
Write-Host "`nRemoving files on $agent_path and $agent_data ..." -ForegroundColor Green
echo aaa
$pk_file=$agent_data+"\id_labadmin-agent_win.pk"
echo bbb
$acl=Get-Acl $pk_file
echo ccc
$acl.SetAccessRuleProtection($true, $false)
echo ddd
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
echo eee
$adminsgrp_name=(New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([type]'System.Security.Principal.NTAccount').value
echo fff
$acl.SetOwner((New-Object System.Security.Principal.Ntaccount($adminsgrp_name)))
echo ggg
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminsgrp_name, "FullControl", "Allow")))
echo hhh
Set-Acl -Path $pk_file -AclObject $acl

echo iii
Remove-Item -Recurse -Force -Path $agent_data
echo jjj
Remove-Item -Recurse -Force -Path $agent_path
