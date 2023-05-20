# Labadmin Script Server Agent for Windows
## Install with PowerShell
Prerequisites:
  * Install .Net Framework 4.7.2: https://support.microsoft.com/es-es/topic/microsoft-net-framework-instalador-sin-conexi%C3%B3n-4-7-2-para-windows-05a72734-2127-a15d-50cf-daf56d5faec2
  * Install WMF 5.1: https://docs.microsoft.com/es-es/powershell/scripting/windows-powershell/wmf/setup/install-configure?view=powershell-7.2

Instal execution this PowerShell command with admin privileges:
```
Set-ExecutionPolicy Bypass -Scope Process -Force; [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072; iex ((New-Object System.Net.WebClient).DownloadString('https://raw.githubusercontent.com/leomarcov/labadmin-script_server_agent/main/windows/install.ps1'))
```

