[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation
try {
    [string]$ZipPath = Get-VstsInput -Name ZipPath -Require
    [string]$ServerName = Get-VstsInput -Name ServerName -Require
    [bool]$DoNotDeleteAdditionalFiles = Get-VstsInput -Name DoNotDeleteAdditionalFiles -AsBool
    [string]$ParametersPath = Get-VstsInput -Name ParametersPath
    [string]$AdditionalParameters = Get-VstsInput -Name AdditionalParameters

    Write-Host "Starting IISDeploy task"
    Write-Verbose "Task parameters:"
    Write-Verbose "ZipPath: $ZipPath"
    Write-Verbose "ServerName: $ServerName"
    Write-Verbose "DoNotDeleteAdditionalFiles: $DoNotDeleteAdditionalFiles"
    Write-Verbose "ParametersPath: $ParametersPath"
    Write-Verbose "AdditionalParameters: $AdditionalParameters"

    if ($ZipPath -notmatch '\.zip') {
        throw "The package should be a .zip file"
    }

    if (-not($ParametersPath) -or $ParametersPath -eq $env:SYSTEM_DEFAULTWORKINGDIRECTORY) {
        $ParametersPath = [System.IO.Path]::ChangeExtension($ZipPath, ".SetParameters.xml")
        Write-Verbose "Compute ParametersPath: $ParametersPath"
    }

    . $PSScriptRoot\Deploy-Website.ps1
    . $PSScriptRoot\ps_modules\VstsTaskSdk\LoggingCommandFunctions.ps1
    $process = Deploy-Website -Package $ZipPath -Server $ServerName -ParamFile $ParametersPath -addDoNotDeleteRule $DoNotDeleteAdditionalFiles -additionalParameters $AdditionalParameters
    if ($process.ExitCode -ne 0) {
        throw "Errors when running MSDeploy (exit code = $($process.ExitCode))"
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