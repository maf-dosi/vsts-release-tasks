[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation
. $PSScriptRoot\Deploy-Website.ps1
. $PSScriptRoot\ps_modules\VstsTaskSdk\LoggingCommandFunctions.ps1
try {
    [string]$ZipPath = Get-VstsInput -Name ZipPath -Require
    [string]$ServerNames = Get-VstsInput -Name ServerNames -Require
    [string]$ParametersPath = Get-VstsInput -Name ParametersPath

    Write-Host "Starting IISDeploy task to ""$ServerNames"""

    if ($ZipPath -notmatch '\.zip') {
        throw "The package should be a .zip file"
    }

    foreach($serverName in $ServerNames.Split(';', [System.StringSplitOptions]::RemoveEmptyEntries)) {

        $process = Deploy-Website -Package $ZipPath -Server $ServerName -ParametersPath $ParametersPath
        if ($process.ExitCode -ne 0) {
            throw "Errors when running MSDeploy (exit code = $($process.ExitCode),server = $server)"
        }
    }
}
catch {
    Write-Host "##vso[task.logissue type=error;] MsDeploy Error: $_"
    Write-SetResult -Result Failed -DoNotThrow
}
finally {
    Write-Host "Ending IISDeploy task"
    Trace-VstsLeavingInvocation $MyInvocation
}