# PREREQUISITES:
#  -Install .Net Framework 4.7.2: https://support.microsoft.com/es-es/topic/microsoft-net-framework-instalador-sin-conexi%C3%B3n-4-7-2-para-windows-05a72734-2127-a15d-50cf-daf56d5faec2
#  -Install WMF 5.1: https://docs.microsoft.com/es-es/powershell/scripting/windows-powershell/wmf/setup/install-configure?view=powershell-7.2

#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
	$agent_path=$ENV:ProgramFiles+"\labadmin-script_server_agent"
	$agent_file=$agent_path+"\labadmin-script_server_agent.ps1"
	$localuser="labadmin"

#===============================================================================
#  CREATE LOCAL USER FOR SCRIPT EXECUTION
#===============================================================================
if (-not (Get-LocalUser -Name $nombreUsuario -ErrorAction SilentlyContinue)) {
	Write-Host "`nCreating local user $agent_path ..." -ForegroundColor Green
	New-LocalUser -Name $localuser -FullName "Labadmin Script Server Agent" -AccountNeverExpires -Disabled -NoPassword
	Add-LocalGroupMember -Member $localuser -SID "S-1-5-32-544"			# Add user to local Administrators group
}

# EXEC INSTALL AS LABADMIN USER
Invoke-Command -ComputerName localhost -Credential (Get-Credential -Credential $localuser) -ScriptBlock {
	$agent_path=$Using:agent_path
	$agent_file=$Using:agent_file
	$localuser=$Using:localuser

	#===============================================================================
	#  INSTALL FILES
	#===============================================================================
	Write-Host "`nCreating files on $agent_path ..." -ForegroundColor Green
	if (-not (Test-Path $agent_path)) {	New-Item -ItemType Directory -Path $agent_path } 
	$url="https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows"
	Invoke-WebRequest -Uri ($url+"/labadmin-script_server_agent.ps1") -OutFile ($agent_path+"\labadmin-script_server_agent.ps1")
	Invoke-WebRequest -Uri ($url+"/install.ps1") -OutFile ($agent_path+"\install.ps1")
	if (-not (Test-Path ($agent_path+"\log.txt"))) { Invoke-WebRequest -Uri ($url+"/config.ps1") -OutFile ($agent_path+"\config.ps1") }
	if (-not (Test-Path ($agent_path+"\log.txt"))) { Invoke-WebRequest -Uri ($url+"/id_labadmin-agent_win.pk") -OutFile ($agent_path+"\id_labadmin-agent_win.pk") }
	if (-not (Test-Path ($agent_path+"\log.txt"))) { New-Item -ItemType File -Path ($agent_path+"\log.txt") -Force }
	
	# SET PRIVATE KEYS PERMISSIONS
	$pk_file=$agent_path+"\id_labadmin-agent_win.pk"
	$acl=Get-Acl $pk_file
	$acl.SetAccessRuleProtection($true, $false)
	$acl.Access | ForEach-Object { $acl.RemoveAccessRule($_) }
	$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule($localuser, "FullControl", "Allow")))
	Set-Acl -Path $pk_file -AclObject $acl


	#===============================================================================
	#  W7: ENABLE TLS 1.2
	#===============================================================================
	if ([System.Environment]::OSVersion.Version.Major -eq 6) {
		Write-Host "`nEnabling TLS 1.2 ..." -ForegroundColor Green
		Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
		Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
		[Net.ServicePointManager]::SecurityProtocol
	}

	#===============================================================================
	#  INSTALL POSH-SSH
	#===============================================================================
	Write-Host "`nInstalling Posh-SSH module..." -ForegroundColor Green
	Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
	Install-Module -Name Posh-SSH -Force
	# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno 
	# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno -KeyFile 'c:\windows\...'

	#===============================================================================
	#  CREATE SCHEDULE JOB
	#===============================================================================
	Write-Host "`nCrearing scheduled job..." -ForegroundColor Green
	Unregister-ScheduledJob labadmin-script_server-agent -ErrorAction SilentlyContinue
	$job_opt = New-ScheduledJobOption -RunElevated -RequireNetwork
	Register-ScheduledJob -Name labadmin-script_server-agent -FilePath $agent_file -Trigger (New-JobTrigger -AtStartup -RandomDelay 00:01:00) -ScheduledJobOption $job_opt
	# List jobs: get-job
	# Show job messages: (get-job)[-1].error
	# Show job messages: (get-job)[-1].output

}
