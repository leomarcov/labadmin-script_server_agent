#Requires -RunAsAdministrator

#!/usr/bin/env bash
#===================================================================================
# LABADMIN SCRIPT SERVER AGENT FOR WINDOWS
#         FILE: labadmin-script_server_agent.ps1
#  DESCRIPTION: Labadmin script server client agent for Windows hosts
#
#       AUTHOR: Leonardo Marco (labadmin@leonardomarco.com)
#	   LICENSE: GNU General Public License v3.0
#      VERSION: 2024.02
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
# DESCRIPTION: write in log file using format: [DATETIME] [STATUS] [ACTION] [SCRIPT] MSG
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

	$datetime="["+(Get-Date -Format "MM-dd-yyyy HH:mm:ss")+"] "
	$status="[${status}] "
	$action="[$action] "
 	if($script) { $script="[${script}] " }
    if($message) { $message=$message.Replace("`r`n", " / ") }

	$log_msg="${datetime}${status}${action}${script}${message}"
	Add-Content -Force -Path $log_path -Value $log_msg
}


#=== FUNCTION ==================================================================
#        NAME: wait_connection
# DESCRIPTION: wait until server connection is active or exit if cant connect
#===============================================================================
function wait_connection {
	$n=20		# Number of tries
	$d=10		# Delay in seconds in each time

	for(; $n -gt 0; $n--) {
		if((Test-Connection $sshaddress -Count 1 -ErrorAction SilentlyContinue)) { return }
		Write-Host "Waiting for server connection..."
		Start-Sleep $d
	}
	
	Write-Host -e "\e[1m\e[31mTimeout waiting for connection\e[0m"
 	log -Status "ERR" -Action -"ETH " 
	exit 1
}



#=== FUNCTION ==================================================================
#        NAME: call_script_server
# DESCRIPTION: call ssh labadmin_script-server manager
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

	Invoke-SSHCommand -SessionId $session.SessionId -Command "$cmd"
}




#### INITIALIZATION
# Check server connection
wait_connection		
# Open SSH session
$session = New-SSHSession -ComputerName $sshaddress -Port $sshport -Credential (New-Object System.Management.Automation.PSCredential($sshuser, (new-object System.Security.SecureString))) -KeyFile $sshprivatekey_path
if(!$?) { log -Status "ERR" -Action "SSH "; exit $LASTEXITCODE }


#### GET PENDING SCRIPT LIST
Write-Output "Getting pending scripts list..."
$call_output=call_script_server -Action "list" 

if($call_output.ExitStatus -ne 0) {
    Write-Error "Error getting pending scripts list: $call_output"
    $call_output.Output
    log -Status "ERR" -Action "LIST" -Message $call_output.Output
    exit 1
}

$script_list=$call_output.Output
if(!$script_list) {	Write-Output "0 pending scripts"; exit 0 }
$script_list
log -Status "OK " -Action "LIST" -Message $script_list


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
		log -Status "ERR" -Action "GET " -Script "$script" -Message $call_output.Output
		continue
	}
    $script_code=$call_output.Output -join "`n"
    
	# SAVE SCRIPT
 	$script_path="["+(Get-Date -Format "yyy-MM-dd HH.mm.ss")+"] "+${script}.split(" ",2)[1]
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
        log -Status "OK " -Action "EXEC" -Script $script
        call_script_server -Action "exec_ok" -Script $script *>$null
    } else {
		Write-Output "Error executing script $script"
		log -Status "ERR" -Action "EXEC" -Script $script -Message $exec_msg
		call_script_server -Action "exec_error" -Script $script -Message $exec_msg.replace("`n", " \ ").substring(0,[Math]::Min($exec_msg.Length, 50))+" ..." *>$null
    }
}

