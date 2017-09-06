function Deploy-Website {
    [CmdletBinding()]
    param(
        [string]$Package,
        [string]$Server,
        [string]$ParamFile,
        [bool]$addDoNotDeleteRule,
        [string]$additionalParameters)
        
    Trace-VstsEnteringInvocation $MyInvocation
    try {
        Write-Verbose "Deploy-Website parameters:"
        Write-Verbose "Package: $Package"
        Write-Verbose "Server: $Server"
        Write-Verbose "ParamFile: $ParamFile"
        Write-Verbose "addDoNotDeleteRule: $addDoNotDeleteRule"
        Write-Verbose "additionalParameters: $additionalParameters"

        $MSDeployKey = 'HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3' 
        if (!(Test-Path $MSDeployKey)) { 
            throw "Could not find MSDeploy path. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
        } 

        $InstallPath = (Get-ItemProperty $MSDeployKey).InstallPath 
        if (!$InstallPath -or !(Test-Path $InstallPath)) { 
            throw "Could not find MSDeploy at '$InstallPath'. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
        } 

        $msdeploy = Join-Path $InstallPath "msdeploy.exe" 
        if (!(Test-Path $MSDeploy)) { 
            throw "Could not find MSDeploy. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
        }

        $PublishUrl = "http://$Server/MsDeployAgentService"
	
        # DEPLOY!
        $argumentArray = [string[]]@(
            "-verb:sync",
            "-source:package='$Package'",
            "-dest:auto,computerName='$PublishUrl'",
            "-setParamFile:""$ParamFile""")
	
        if ($addDoNotDeleteRule) {
            $argumentArray += "-enableRule:DoNotDeleteRule"
        }

        $arguments = ""
        foreach ($arg in $argumentArray) {
            $arguments += $arg + " "
        }
        $arguments += $additionalParameters

        Write-Host "Deploying package to $PublishUrl"
        Write-Verbose "Argument list: $arguments"
        $process = Start-Process -FilePath $msdeploy -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        return $process
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}