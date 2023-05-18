
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
$hostname=[Environment]::MachineName
$agent_path=$ENV:ProgramFiles+"\labadmin-script_server_agent"
. ${agent_path}\config.ps1				# LOAD CONFIG VARIABLES


#=== FUNCTION ==================================================================
#        NAME: log
# DESCRIPTION: write in log file using format: [date time] HOSTNAME ACTION EXEC_MSG
#===============================================================================
function log {
	$action=$args[0]
	$script=$args[1]
	$exec_msg=$args[2]

	$action="["+$action.toUpper()+"]"
	$action_width=11; if($action.Length -lt $action_width) { $action=$action.toUpper()+" "*($action_width-$action.Length) }
	if($script) { $script="[$script]`t" }

	$log_msg="["+(Get-Date -Format "MM-dd-yyyy HH:mm:ss")+"] $action $script"
	if ($exec_msg) { 
    $exec_msg=$exec_msg -join "`n"
    $log_msg=$log_msg+@"
`n#### EXEC OUTPUT #############################################################
${exec_msg} 
##############################################################################
"@ }
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
	$action=$args[0]
	$script=$args[1]
	$exec_msg=$args[2]
	
	$cmd="bash $sshcmd -h $hostname -r $repository -a $action"
	if($actionl) { $cmd="$cmd -a `"$action`"" }
	if($script) { $cmd="$cmd -s `"$script`"" }
	if($exec_msg) { $cmd="$cmd -m `"$exec_msg`"" }

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
$call_output=call_script_server "list" 

if($call_output.ExitStatus -ne 0) {
    Write-Error "Error getting pending scripts list: $call_output"
    $call_output.Output
    log "list_error" "" $call_output
    exit 1
}
$script_list=$call_output.Output
log "list_ok" "" $script_list

if(!$script_list) {
	Write-Output "0 pending scripts"
	exit 0
}
$script_list


#### GET AND EXEC SCRIPTS
ForEach ($script in $($script_list -split "`r`n"))
{
    Write-Output "`n##########################################################################"

	# GET SCRIPT CODE
	Write-Output "Getting script code for: $script"
	$call_output=call_script_server "get" "$script"
	if($call_output.ExitStatus -ne 0) {
		Write-Error "Error getting script code $script"
		$call_output.Output
		log "get_error" "$script" $call_output.Output
		continue
	}
    $script_code=$call_output.Output -join "`n"
    # EXEC SCRIPT
    Write-Output "Executing  script code for: $script"
    $exec_output=(Invoke-Expression -Command $script_code) 2>&1
    $exec_code=$exec_output[-1]
    $exec_msg=$exec_output[0..($exec_output.Length-2)] | Out-String
	$exec_msg
	echo "EXIT CODE: $exec_code"
    if($exec_code) {
        log "exec_ok" $script
        call_script_server "exec_ok" $script *>$null
    } else {
		Write-Output "Error executing script code $script"
		log "exec_error" $script $exec_msg
		call_script_server "exec_error" $script $exec_msg.replace("`n", " \ ").substring(0,[Math]::Min($exec_msg.Lenght, 50))+" ..." *>$null
    }
}

