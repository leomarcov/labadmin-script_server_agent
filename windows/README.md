# Labadmin Script Server Agent for Windows
## Install
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('[https://community.chocolatey.org/install.ps1](https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows/install.ps1)'))
```

