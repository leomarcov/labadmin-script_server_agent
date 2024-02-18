#Requires -RunAsAdministrator

#!/usr/bin/env bash
#===================================================================================
# LABADMIN SCRIPT SERVER AGENT INSTALL FOR WINDOWS
#         FILE: install.ps1
#  DESCRIPTION: Labadmin script server client agent install for Windows hosts
#
#       AUTHOR: Leonardo Marco (labadmin@leonardomarco.com)
#	   LICENSE: GNU General Public License v3.0
#      VERSION: 2024.02
#      CREATED: 28.06.2022
#=================================================================================== 


#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\labadmin-script_server_agent"
$agent_data="${ENV:ALLUSERSPROFILE}\labadmin\labadmin-script_server_agent"
$agent_file="${agent_path}\lss-agent.ps1"
$agent_user="labadmin"

#===============================================================================
#  CHECK CREDENTIALS
#===============================================================================
# Run as admin (#Requires not found when load install from URL)
if(!((New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
	Write-Error "Must exec as Administrator"
	exit 1
}

#===============================================================================
#  CREATE LOCAL USER FOR SCRIPT EXECUTION
#===============================================================================
# Get agent_user credentials
Write-Host "`nInsert $agent_user user credentials..." -ForegroundColor Green
while(!$agent_user_cred -OR $agent_user_cred.Username -ne $agent_user) { $agent_user_cred = Get-Credential -Credential $agent_user }

if (-not (Get-LocalUser -Name $agent_user -ErrorAction SilentlyContinue)) {
	Write-Host "`nCreating local user $agent_user" -ForegroundColor Green
	New-LocalUser -Name $agent_user -FullName "Labadmin Script Server Agent" -AccountNeverExpires -Password $agent_user_cred.Password
	Add-LocalGroupMember -Member $agent_user -SID "S-1-5-32-544"			# Add user to local Administrators group
	# Hide user from login screen:
	New-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -Force | New-ItemProperty -Name $agent_user -Value 0 -PropertyType DWord -Force
} else {
	Set-LocalUser -Name $agent_user -Password $agent_user_cred.Password
}

#===============================================================================
#  INSTALL FILES

#===============================================================================
Write-Host "`nCreating files on $agent_path and $agent_data ..." -ForegroundColor Green
if(!(Test-Path $agent_path)) {	New-Item -ItemType Directory -Path $agent_path } 
if(!(Test-Path $agent_data)) { New-Item -ItemType Directory -Force -Path $agent_data }

$url="https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows"
Invoke-WebRequest -Uri ($url+"/lss-agent.ps1") -OutFile ($agent_path+"\lss-agent.ps1")
Invoke-WebRequest -Uri ($url+"/lss-config-schedule.ps1") -OutFile ($agent_path+"\lss-config-schedule.ps1")
Invoke-WebRequest -Uri ($url+"/install.ps1") -OutFile ($agent_path+"\install.ps1")
Invoke-WebRequest -Uri ($url+"/uninstall.ps1") -OutFile ($agent_path+"\uninstall.ps1")
Invoke-WebRequest -Uri ($url+"/update.ps1") -OutFile ($agent_path+"\update.ps1")
if (-not (Test-Path ($agent_data+"\log.txt"))) { Invoke-WebRequest -Uri ($url+"/config.ps1") -OutFile ($agent_data+"\config.ps1") }
if (-not (Test-Path ($agent_data+"\log.txt"))) { Invoke-WebRequest -Uri ($url+"/id_lss-agent.pk") -OutFile ($agent_data+"\id_lss-agent.pk") }
if (-not (Test-Path ($agent_data+"\log.txt"))) { New-Item -ItemType File -Path ($agent_data+"\log.txt") -Force }

# Set key permissions
$pk_file="${agent_data}\id_lss-agent.pk"
$acl=Get-Acl $pk_file
$acl.SetAccessRuleProtection($true, $false)
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
$adminsgrp_name=(New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([type]'System.Security.Principal.NTAccount').value
$acl.SetOwner((New-Object System.Security.Principal.Ntaccount($adminsgrp_name)))
$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminsgrp_name,"FullControl", "Allow")))
Set-Acl -Path $pk_file -AclObject $acl

#===============================================================================
#  INSTALL POSH-SSH
#===============================================================================
if(!(Get-Module Posh-SSH)) { 
	Write-Host "`nInstalling Posh-SSH module..." -ForegroundColor Green
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12		# ENABLE TLS 1.2
	#Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
	Install-Module -Name Posh-SSH -Force
	# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno 
	# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno -KeyFile 'c:\windows\...'
}

#===============================================================================
#  CREATE SCHEDULE JOB
#===============================================================================
Write-Host "`nCrearing scheduled job..." -ForegroundColor Green
Start-Process powershell -Credential $agent_user_cred -ArgumentList "-File `"${agent_path}\lss-config-schedule.ps1`" -register"




