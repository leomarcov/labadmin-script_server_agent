#Requires -RunAsAdministrator

#===================================================================================
# LABADMIN SCRIPT SERVER AGENT FOR WINDOWS
#         FILE: lss-agent.ps1
#  DESCRIPTION: Labadmin script server client agent for Windows hosts
#
#       AUTHOR: Leonardo Marco (labadmin@leonardomarco.com)
#	   LICENSE: GNU General Public License v3.0
#      VERSION: 2024.11
#      CREATED: 2022.06.28
#=================================================================================== 


#===============================================================================
#  GLOBAL CONFIG VARIABLES
#===============================================================================
$agent_path="${ENV:ProgramFiles}\labadmin\lss-agent"						# Agent program install path
$agent_data="${ENV:ALLUSERSPROFILE}\labadmin\lss-agent"						# Agent program data path
$scripts_path="${agent_data}\scripts"										# Downloaded scripts path stored
$hostname=[Environment]::MachineName									    # Hostname 
$sshcmd="/opt/labadmin-script_server/lss-srv"							    # Labadmin script server command path in remote server
$agent_version=Get-Content -LiteralPath "${agent_path}\version"				# Agent version

# LOAD CONFIG VARIABLES
. ${agent_data}\config.ps1				


#=== FUNCTION ==================================================================
#        NAME: log
# DESCRIPTION: write line in log file using format: [DATETIME] [ACTION] [STATUS] [SCRIPT] MSG
#===============================================================================
function log {
	Param(
      [parameter(Mandatory=$true)]
	  [String]$Action,
	  [parameter(Mandatory=$true)]
	  [String]$Status,	  
      [String]$Script,
	  [String]$Message
   )

	$datetime="["+(Get-Date -Format "yyyy-MM-dd HH:mm:ss")+"] "
	$action="[$action]".PadRight(7)
	if ($action -eq "LIST") { $action="`n${action}"}
	$status="[${status}]".PadRight(6)	
 	if($script) { $script="[${script}] " }
    if($message) { $message="$($message.Replace("`r`n", " / "))" }

	$log_msg="${datetime}${action}${status}${script}${message}"
	Add-Content -Force -Path $log_path -Value $log_msg
}


#=== FUNCTION ==================================================================
#        NAME: wait_connection
# DESCRIPTION: wait until server connection is active or exit if cant connect
#===============================================================================
function wait_connection {
	$n=30		# Number of tries

	for(; $n -gt 0; $n--) {
		if((Test-NetConnection $sshaddress -Port $sshport -ErrorAction SilentlyContinue).TcpTestSucceeded) { return }
		Write-Host "Waiting for server connection..."	
	}
	
	Write-Host -e "\e[1m\e[31mTimeout waiting for connection\e[0m"
 	log -Action -"TIME" -Status "ERR" -Message "Time out connecting to server"
	exit 1
}



#=== FUNCTION ==================================================================
#        NAME: call_script_server
# DESCRIPTION: call ssh labadmin_script-server manager
#===============================================================================
function call_script_server {
	Param(
	  [parameter(Mandatory=$true)]
	  [String]$action,
	  [String]$script,
	  [String]$message
   )	
	
	$cmd="bash $sshcmd -v $agent_version -h $hostname -M $mac -r $repository -a $action"
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
if(!$?) { log -Action "SSH" -Status "ERR" -Message "Error connecting to SSH Server"; exit $LASTEXITCODE }
# Get default MAC address
$mac = (Get-NetAdapter | Where-Object { $_.ifIndex -eq (Find-NetRoute -RemoteIPAddress 8.8.8.8)[1].ifIndex }).MacAddress


#### GET PENDING SCRIPT LIST
Write-Output "`nGETTING PENDING SCRIPT LISTS..."
$call_output=call_script_server -Action "list" 
$call_output_str=($call_output.Output | Out-String).Trim()					# Convert to string
if($call_output.ExitStatus -ne 0) {
Write-Error "Error getting pending scripts list: ${call_output}`n"
    $call_output.Output
    log -Action "LIST" -Status "ERR" -Message $call_output_str
    exit 1
}

$script_list=$call_output_str
if(!$script_list) {	Write-Output "0 pending scripts`n"; exit 0 }
log -Action "LIST" -Status "OK" -Message "|$($script_list.Replace("`r`n", "|"))|"
$script_list -Replace '(?m)^(?=.)', '  - '


Write-Output "`n`nEXECUTING SCRIPTS..."

#### GET AND EXEC SCRIPTS
ForEach ($script in $($script_list -split "`r`n")) {   
	Write-Output "`n_______________________________________________________________________________________________________________"
	Write-Output "SCRIPT: $script"

	# GET SCRIPT CODE
	Write-Output "  * Getting code: $script"
	$call_output=call_script_server -Action "get" -Script "$script"
	$call_output_str=($call_output.Output | Out-String).Trim()					# Convert to string
	if($call_output.ExitStatus -ne 0) {
		Write-Error "  * Error getting script code $script"
		$call_output.Output
		log -Action "GET" -Status "ERR" -Script "$script" -Message $call_output_str
		continue
	}
    $script_code=$call_output_str
    
	# SAVE SCRIPT
  	if(!(Test-Path $scripts_path)) { New-Item -ItemType Directory -Force -Path $scripts_path }
 	$script_path="["+(Get-Date -Format "yyy-MM-dd HH.mm.ss")+"] "+${script}.split(" ",2)[1]
	$script_path=$script_path.Split([IO.Path]::GetInvalidFileNameChars()) -join '_'				# Remplace illegal path chars to _
  	$script_log="${scripts_path}\${script_path}.log"
    $script_path="${scripts_path}\${script_path}.ps1"
	Write-Output "  * Saving script: $script_path"
	$script_code | Out-File -Force -LiteralPath $script_path
	
 	# EXEC SCRIPT 
    Write-Output "  * Executing: $script"
    Write-Output "`n+--- OUTPUT -----------------------------------------------------------------+"
	& $script_path 2>&1 | Tee-Object -LiteralPath $script_log				# Exec saved script and redirect log to script log file
    $script_exitstatus=$?; $script_exitcode=$LASTEXITCODE
	Write-Output "`n+----------------------------------------------------------------------------+"


	# SEND EXIT STATUS AND LOG
    if($script_exitstatus) {
		Write-Output "  * Execution termination: OK"
		Write-Output "  * Saved output: $script_log"
        log -Action "EXEC" -Status "OK" -Script $script
		call_script_server -Action "exec_ok" -Script $script | Out-Null
	} else {
		Write-Output "  * Execution termination: ERROR (${script_exitcode})"
		Write-Output "  * Saved output: $script_log"
		$script_output=Get-Content -LiteralPath $script_log | Out-String
		log -Action "EXEC" -Status "ERR" -Script $script -Message (($script_output -split "\r?\n" | Select-Object -First 10) -join "/")
		call_script_server -Action "exec_error" -Script $script -Message $script_output | Out-Null
    }
	Write-Output "_______________________________________________________________________________________________________________`n"
}

Write-Output "`n"
