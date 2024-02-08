# Labadmin Script Server Agent for Windows
## Install with PowerShell
For install exec this PowerShell command with admin privileges:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows/install.ps1'))
```
  * Edit config file `C:\Program Data\labadmin\labadmin-script_server_agent\config.ps1' and set SSH config.
  * Copy private key lss-agent user in SSH server on `C:\Program Data\labadmin\labadmin-script_server_agent\`.


## Uninstall with PowerShell
For install exec this PowerShell command with admin privileges:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows/uninstall.ps1'))
```
