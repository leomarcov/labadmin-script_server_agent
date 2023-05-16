# Install .Net Framework 4.7.2: https://support.microsoft.com/es-es/topic/microsoft-net-framework-instalador-sin-conexi%C3%B3n-4-7-2-para-windows-05a72734-2127-a15d-50cf-daf56d5faec2
# Install WMF 5.1: https://docs.microsoft.com/es-es/powershell/scripting/windows-powershell/wmf/setup/install-configure?view=powershell-7.2

#### INSTALL GITHUB ###########################################################
$url="https://github.com/leomarcov/labadmin-script_server_agent/archive/refs/heads/main.zip"
$tmp = "$env:TEMP\labadmin-script_server_agent.zip"
Invoke-WebRequest -Uri $url -OutFile $tmp
Expand-Archive -Path $tmp -DestinationPath $ENV:ProgramFiles
del $tmp
#################################################################################


#### W7 ONLY: ENABLE TLS 1.2 #####################################################
if ([System.Environment]::OSVersion.Version.Major -eq 6) {
	Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
	Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
	[Net.ServicePointManager]::SecurityProtocol
}

# INSTALL POSH-SSH
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
Install-Module -Name Posh-SSH -Force
# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno 
# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno -KeyFile 'c:\windows\...'

# CREATE JOB SCHEDULE
Unregister-ScheduledJob labadmin-script_server-agent
$agent_path=$ENV:ProgramFiles+"\labadmin-script_server_agent\labadmin-script_server_agent.ps1"
$job_opt = New-ScheduledJobOption -RunElevated -RequireNetwork
$job_cred = Get-Credential -UserName labadmin
Register-ScheduledJob -Name labadmin-script_server-agent -FilePath $agent_path -Trigger (New-JobTrigger -AtStartup -RandomDelay 00:01:00) -ScheduledJobOption $job_opt -Credential $job_cred
# List jobs: get-job
# Show job messages: (get-job)[0].error


