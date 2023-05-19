# Labadmin Script Server Agent for Windows
## Install with PowerShell
Instal execution this PowerShell command with admin privileges:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows/install.ps1'))
```

