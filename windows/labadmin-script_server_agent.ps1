#Requires -RunAsAdministrator

#!/usr/bin/env bash
#===================================================================================
# LABADMIN SCRIPT SERVER AGENT FOR WINDOWS
#         FILE: labadmin-script_server_agent.ps1
#  DESCRIPTION: Labadmin script server client agent for Windows hosts
#
#       AUTHOR: Leonardo Marco (labadmin@leonardomarco.com)
#	   LICENSE: GNU General Public License v3.0
#      VERSION: 2022.06
#      CREATED: 28.06.2022
#=================================================================================== 


#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_data="${ENV:ALLUSERSPROFILE}\labadmin\labadmin-script_server_agent"  # Agent program data path
$scripts_path="${agent_data}\scripts"										# Downloaded scripts path stored
$hostname=[Environment]::MachineName									    # Hostname 
$sshcmd="/opt/labadmin-script_server/lss-srv"							    # Labadmin script server command path in remote server

# LOAD CONFIG VARIABLES
. ${agent_data}\config.ps1				


#=== FUNCTION ==================================================================
#        NAME: log
# DESCRIPTION: write in log file using format: [date time] [STATUS] [ACTION] [SCRIPT] MSG
#===============================================================================
function log {
	Param(
	  [parameter(Mandatory=$true)]
	  [String]$Status,
      [parameter(Mandatory=$true)]
	  [String]$Action,
      [String]$Script,
	  [String]$Message
   )

	$status="["+$status.toUpper()+"] "
	$action="["+$action.toUpper()+"] "
 	if($script) { $script="[{$script}] " }
    if($message) { $message=$message.Replace("`r`n", " / ") 	}

	$log_msg="["+(Get-Date -Format "MM-dd-yyyy HH:mm:ss")+"] ${status}${action}${script}${message}"
	Add-Content -Path $log_path -Value $log_msg
}


#=== FUNCTION ==================================================================
#        NAME: wait_connection
# DESCRIPTION: wait until server connection is active or exit if cant connect
#===============================================================================
function wait_connection {
	$n=10	# Number of tries
	$d=10	# Delay in seconds in each time

	for(; $n -gt 0; $n--) {
		if((Test-Connection $sshaddress -Count 1 -ErrorAction SilentlyContinue)) { return }
		Write-Host "Waiting for server connection..."
		Start-Sleep $d
	}
	
	Write-Host -e "\e[1m\e[31mTimeout waiting for connection\e[0m"
	exit 1
}


#=== FUNCTION ==================================================================
#        NAME: check_admin_privileges
# DESCRIPTION: check if current user has administrator privileges
#===============================================================================
function check_admin_privileges {
	return (New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}


#=== FUNCTION ==================================================================
#        NAME: call_script_server
# DESCRIPTION: call ssh labadmin_script-server manager
# PARAMETERS:
#	$1 	action
#	$2 	script
#	$3 	exec_msg
#===============================================================================
function call_script_server {
	Param(
	  [parameter(Mandatory=$true)]
	  [String]$Action,
	  [String]$Script,
	  [String]$Message
   )	
	
	$cmd="bash $sshcmd -h $hostname -r $repository -a $action"
	if($action) { $cmd="$cmd -a `"$action`"" }
	if($script) { $cmd="$cmd -s `"$script`"" }
	if($message) { $cmd="$cmd -m `"$message`"" }

	return Invoke-SSHCommand -SessionId $session.SessionId -Command "$cmd"
}






#### INITIALIZATION
# Check admin
if(!(check_admin_privileges)) {
	Write-Error "Must exec as Administrator"
	exit 1
}
# Check server connection
wait_connection		
# Open SSH session
$session = New-SSHSession -ComputerName $sshaddress -Port $sshport -Credential (New-Object System.Management.Automation.PSCredential($sshuser, (new-object System.Security.SecureString))) -KeyFile $sshprivatekey_path
if(!$?) { exit $LASTEXITCODE }


#### GET PENDING SCRIPT LIST
Write-Output "Getting pending scripts list..."
$call_output=call_script_server -Action "list" 

if($call_output.ExitStatus -ne 0) {
    Write-Error "Error getting pending scripts list: $call_output"
    $call_output.Output
    log -Status "err" -Action "list" -Message $call_output
    exit 1
}
$script_list=$call_output.Output

if(!$script_list) {
	Write-Output "0 pending scripts"
	exit 0
}
$script_list
log -Status "ok " -Action "list" -Message $script_list



#### GET AND EXEC SCRIPTS
ForEach ($script in $($script_list -split "`r`n"))
{
    Write-Output "`n##########################################################################"

	# GET SCRIPT CODE
	Write-Output "Getting script code for: $script"
	$call_output=call_script_server -Action "get" -Script "$script"
	if($call_output.ExitStatus -ne 0) {
		Write-Error "Error getting script code $script"
		$call_output.Output
		log -Status "err" -Action "get " -Script "$script" -Message $call_output.Output
		continue
	}
    $script_code=$call_output.Output -join "`n"
    
	# SAVE SCRIPT
 	$script_path="["+(Get-Date -Format "yyy-MM-dd HH.mm.ss")+"] ${script}"
	$script_path=$script_path.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'				# Remplace illegal path chars to _
  	$script_log="${scripts_path}\${script_path}.log"
    $script_path="${scripts_path}\${script_path}.ps1"
	Write-Output "Saving script $script in $script_path"
	$script_code | Out-File -Force -LiteralPath $script_path
	
 	# EXEC SCRIPT 
    Write-Output "Executing  script: $script"
	& $script_path 2>&1 | Tee-Object -LiteralPath $script_log				# Exec saved script and redirect log to script log file

	# SEND EXIT STATUS AND LOG
    if($?) {
        log -Status "ok " -Action "exec" -Script $script
        call_script_server -Action "exec_ok" -Script $script *>$null
    } else {
		Write-Output "Error executing script $script"
		log -Status "err" -Action "exec" -Script $script -Message $exec_msg
		call_script_server -Action "exec_error" -Script $script -Message $exec_msg.replace("`n", " \ ").substring(0,[Math]::Min($exec_msg.Length, 50))+" ..." *>$null
    }
}

