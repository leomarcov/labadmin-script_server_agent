# Install .Net Framework 4.7.2: https://support.microsoft.com/es-es/topic/microsoft-net-framework-instalador-sin-conexi%C3%B3n-4-7-2-para-windows-05a72734-2127-a15d-50cf-daf56d5faec2
# Install WMF 5.1: https://docs.microsoft.com/es-es/powershell/scripting/windows-powershell/wmf/setup/install-configure?view=powershell-7.2

#### INSTALL GITHUB ###########################################################
$file = 'gh_2.29.0_windows_amd64.msi'
$link = "https://github.com/cli/cli/releases/download/v2.29.0/$file"
$soft_name = 'GitHub'
$find = Get-WmiObject -Class Win32_Product -Filter "Name LIKE `'$soft_name`'"
if ($find -eq $null) {
    $tmp = "$env:TEMP\$file"
    $client = New-Object System.Net.WebClient
    $client.DownloadFile($link, $tmp)
    msiexec /i $tmp /qn
    del $tmp
    echo "Tried installing $soft_name"
} else {
    echo "ERROR: $soft_name is already installed."
    echo $find
}
#################################################################################

# CLONE GITHUB PROYECT
cd $ENV:ProgramFiles
git clone "https://github.com/labadmin-script_server_agent"


#### W7 ONLY: ENABLE TLS 1.2 #####################################################
# https://www.delftstack.com/howto/powershell/installing-the-nuget-package-in-powershell/
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\.NetFramework\v4.0.30319' -Name 'SchUseStrongCrypto' -Value '1' -Type DWord
[Net.ServicePointManager]::SecurityProtocol
################################################################################# 


# INSTALL POSH-SSH
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force -Verbose
Install-Module -Name Posh-SSH -Force
# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno 
# Test connection: New-SSHSession -ComputerName 10.0.2.15 -Port 58889 -AcceptKey -Credential alumno -KeyFile 'c:\windows\...'

# CREATE JOB SCHEDULE
Unregister-ScheduledJob labadmin-script_server-agent
$agent_path="C:\ProgramData\labadmin-script_server_agent\labadmin-script_server_agent.ps1"
Register-ScheduledJob -Trigger (New-JobTrigger -AtStartup -RandomDelay 00:01:00) -FilePath $agent_path -Name labadmin-script_server-agent
# List jobs: get-job
# Show job messages: (get-job)[0].error


