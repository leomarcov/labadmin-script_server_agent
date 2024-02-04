#Requires -RunAsAdministrator

#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\labadmin-script_server_agent"
$agent_data="${ENV:ALLUSERSPROFILE}\labadmin\labadmin-script_server_agent"
$agent_file=$agent_path+"\labadmin-script_server_agent.ps1"
$agent_user="labadmin"

#===============================================================================
#  GET agent_user CREDENTIAL
#===============================================================================
Write-Host "`nInsert $agent_user user credentials..." -ForegroundColor Green
$agent_user_cred = Get-Credential -Credential $agent_user -ErrorAction Stop

#===============================================================================
#  CREATE LOCAL USER FOR SCRIPT EXECUTION
#===============================================================================
if (-not (Get-LocalUser -Name $agent_user -ErrorAction SilentlyContinue)) {
	Write-Host "`nCreating local user $agent_path ..." -ForegroundColor Green
	New-LocalUser -Name $agent_user -FullName "Labadmin Script Server Agent" -AccountNeverExpires -Password $agent_user_cred.Password
	Add-LocalGroupMember -Member $agent_user -SID "S-1-5-32-544"			# Add user to local Administrators group
	# Hide user from login screen:
	New-Item 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\SpecialAccounts\UserList' -Force | New-ItemProperty -Name $agent_user -Value 0 -PropertyType DWord -Force
}


#===============================================================================
#  INSTALL FILES
#===============================================================================
Write-Host "`nCreating files on $agent_path ..." -ForegroundColor Green
if (-not (Test-Path $agent_path)) {	New-Item -ItemType Directory -Path $agent_path } 
if(!(Test-Path $agent_data)) {
	New-Item -ItemType Directory -Force -Path $agent_data | Out-Null   
	$acl = Get-Acl $agent_data
	$acl.SetAccessRuleProtection($true, $false)
	$adminsgrp_name=(New-Object System.Security.Principal.SecurityIdentifier 'S-1-5-32-544').Translate([type]'System.Security.Principal.NTAccount').value
	$acl.SetOwner((New-Object System.Security.Principal.Ntaccount($adminsgrp_name)))
	$acl.SetAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($adminsgrp_name,"FullControl", 3, 0, "Allow")))
	Set-Acl -Path $agent_data -AclObject $acl
}

$url="https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows"
Invoke-WebRequest -Uri ($url+"/labadmin-script_server_agent.ps1") -OutFile ($agent_path+"\labadmin-script_server_agent.ps1")
Invoke-WebRequest -Uri ($url+"/install.ps1") -OutFile ($agent_path+"\install.ps1")
if (-not (Test-Path ($agent_data+"\log.txt"))) { Invoke-WebRequest -Uri ($url+"/config.ps1") -OutFile ($agent_data+"\config.ps1") }
if (-not (Test-Path ($agent_data+"\log.txt"))) { Invoke-WebRequest -Uri ($url+"/id_labadmin-agent_win.pk") -OutFile ($agent_data+"\id_labadmin-agent_win.pk") }
if (-not (Test-Path ($agent_data+"\log.txt"))) { New-Item -ItemType File -Path ($agent_data+"\log.txt") -Force }

# SET PRIVATE KEYS PERMISSIONS
$pk_file=$agent_data+"\id_labadmin-agent_win.pk"
$acl=Get-Acl $pk_file
$acl.SetAccessRuleProtection($true, $false)
$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
$acl.SetOwner((New-Object System.Security.Principal.Ntaccount($agentUser)))
$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($agentUser, "FullControl", "Allow")))
Set-Acl -Path $pk_file -AclObject $acl


#===============================================================================
#  INSTALL POSH-SSH
#===============================================================================
if(!(Get-Module Posh-SSH)) { 
	Write-Host "`nInstalling Posh-SSH module..." -ForegroundColor Green
	[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12		# ENABLE TLS 1.2
	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
	if # Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno 
	# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno -KeyFile 'c:\windows\...'
}

#===============================================================================
#  CREATE SCHEDULE JOB
#===============================================================================
Write-Host "`nCrearing scheduled job..." -ForegroundColor Green
Unregister-ScheduledJob labadmin-script_server-agent -ErrorAction SilentlyContinue
$job_opt = New-ScheduledJobOption -RunElevated -RequireNetwork
Register-ScheduledJob -Credential $agent_user_cred -Name labadmin-script_server-agent -FilePath $agent_file -Trigger (New-JobTrigger -AtStartup -RandomDelay 00:01:00) -ScheduledJobOption $job_opt
# List jobs: get-job
# Show job messages: (get-job)[-1].error
# Show job messages: (get-job)[-1].output

