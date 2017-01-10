[CmdletBinding(DefaultParameterSetName = 'None')]
param(
	[string][Parameter(Mandatory=$true)] $Zippath, 
	[string][Parameter(Mandatory=$true)] $Servername,
	[string] $Parameterspath
)

Write-Host "Starting IISDeploy task"
Trace-VstsEnteringInvocation $MyInvocation

try {

	Write-Verbose "Zippath : $Zippath"
	Write-Verbose "Servername : $Servername"
	Write-Verbose "Parameterspath : $Parameterspath"

} catch {

} finally {
	Trace-VstsLeavingInvocation $MyInvocation
}

Write-Host "Ending IISDeploy task"