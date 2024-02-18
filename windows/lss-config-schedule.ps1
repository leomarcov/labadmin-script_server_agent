#Requires -RunAsAdministrator
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
.NOTES
	File Name: lss-config-schedule.ps1
	Author   : Leonardo Marco
#>


Param(
  [parameter(Mandatory=$false]
  [Switch]$enable,
  [Switch]$disable,
  [Switch]$register,
  [Switch]$unregister,
  [Switch]$show
)


#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\labadmin-script_server_agent"
$agent_file="${agent_path}\lss-agent.ps1"
$agent_user="labadmin"

#===============================================================================
#  CHECK LABADMIN USER
#===============================================================================
if([Environment]::UserName -eq $agent_user) {
	Start-Process powershell -Credential $agent_user_cred -ArgumentList '-noprofile -command &{Start-Process "powershell" -ArgumentList "-file $" -verb runas}'
}

#===============================================================================
#  EXEC ACTIONS
#===============================================================================
if($enable) {
	$job=$job=Get-ScheduledJob -Name labadmin-script_server-agent -ErrorAction Stop
	Enable-ScheduledJob $job
} 
elseif($disable) {
	$job=$job=Get-ScheduledJob -Name labadmin-script_server-agent -ErrorAction Stop
	Disable-ScheduledJob $job
}
elseif($register) {
	Unregister-ScheduledJob labadmin-script_server-agent -ErrorAction SilentlyContinue
	Register-ScheduledJob -Name labadmin-script_server-agent -FilePath $agent_file -Trigger (New-JobTrigger -AtStartup -RandomDelay 00:01:00) -ScheduledJobOption (New-ScheduledJobOption -RunElevated -RequireNetwork)
}
elseif($unregister) {
	Unregister-ScheduledJob labadmin-script_server-agent
}
else {
	$job=$job=Get-ScheduledJob -Name labadmin-script_server-agent -ErrorAction Stop
    $job | Format-List -Property Name,Id,Command,Enabled,ExecutionHistoryLength
    $job.options
	get-job
}



