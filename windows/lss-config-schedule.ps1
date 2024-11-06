#===================================================================================
# LABADMIN SCRIPT SERVER AGENT CONFIG SCHEDULE
#         FILE: lss-config-schedule.ps1
#  DESCRIPTION: Labadmin script server script to config scheduled job
#               enable/didable/register/unregister and show scheduled job to run lss-agent
#
#       AUTHOR: Leonardo Marco (labadmin@leonardomarco.com)
#	   LICENSE: GNU General Public License v3.0
#      VERSION: 2024.11
#      CREATED: 2022.06.28
#=================================================================================== 

<#
.SYNOPSIS
  Config labadmin script server agent scheduled job
.PARAMETER enable
  Enable scheduled job
.PARAMETER disable
  Disable scheduled job
.PARAMETER register
  Register scheduled job
.PARAMETER unregisgter
  Unregister scheduled job
.PARAMETER show
  Show scheduled job info
.NOTES
	File Name: lss-config-schedule.ps1
	Author   : Leonardo Marco
#>


Param(
  [Switch]$enable,
  [Switch]$disable,
  [Switch]$register,
  [Switch]$unregister, 
  [Switch]$show
)



#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\lss-agent"
$agent_file="${agent_path}\lss-agent.ps1"
$job_name="lss-agent"
$agent_user="labadmin"


#===============================================================================
#  CHECK LABADMIN USER
#===============================================================================
# Exec as labadmin user
if([Environment]::UserName -ne $agent_user) {
	Write-Output "Enter $agent_user credentials..."
	while(!$agent_user_cred -OR $agent_user_cred.Username -ne $agent_user) { $agent_user_cred = Get-Credential -Credential $agent_user }
	$args = @("-File `"$PSCommandPath`"", "-$($PSBoundParameters.Keys)")
	Write-Output "Executing script ${PSCommandPath} with $agent_user credentials..."
	Start-Process powershell -Credential $agent_user_cred -ArgumentList $args
	exit 
} else { Write-Output " * [OK] Executing script with $agent_user credentials " }
# Exec elevated
if((New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator) -eq $false) {
	$args = @("-noexit -File `"$PSCommandPath`"", "-$($PSBoundParameters.Keys)")
	Write-Output "Executing script ${PSCommandPath} with $agent_user elevated credentials..."
	Start-Process powershell -Verb runas -ArgumentList $args
	exit 
} else { Write-Output " * [OK] Executing script with elevated rights"}


#===============================================================================
#  EXEC ACTIONS
#===============================================================================
if($enable) {
	Enable-ScheduledJob -Name $job_name -ErrorAction Stop
} 
elseif($disable) {
	Disable-ScheduledJob -Name $job_name -ErrorAction Stop
}
elseif($register) {
	Unregister-ScheduledJob -Name $job_name -ErrorAction SilentlyContinue
	Register-ScheduledJob -Name $job_name -FilePath $agent_file -Trigger (New-JobTrigger -AtStartup) -ScheduledJobOption (New-ScheduledJobOption -RunElevated -RequireNetwork)
}
elseif($unregister) {
	Unregister-ScheduledJob -Name $job_name -ErrorAction Stop
}
else {
	$job=Get-ScheduledJob -Name $job_name -ErrorAction Stop
	$job
    $job | Format-List -Property Name,Id,Command,Enabled,ExecutionHistoryLength
    $job.options
	get-job
}


