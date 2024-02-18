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


