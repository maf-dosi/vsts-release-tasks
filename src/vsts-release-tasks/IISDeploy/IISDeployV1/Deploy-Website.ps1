function Deploy-Website {
    [CmdletBinding()]
    param(
        [string] $Package,
        [string] $Server,
        [string] $ParametersPath
    )

    Trace-VstsEnteringInvocation $MyInvocation
    try {
        $PackageName = [System.IO.Path]::GetFileNameWithoutExtension($Package)
        Write-Host "Deploying package '$PackageName' to '$Server'"

        $destinationParameter = DestinationParameter $Server
        $packageParameterFile = Compute-ParameterFile $ParametersPath $Package
        $argumentArray = [string[]]@(
            "-verb:sync",
            "-source:package='$Package'",
            $destinationParameter,
            "-setParamFile:""$packageParameterFile""")

        [bool] $addDoNotDeleteRule = Get-VstsInput -Name DoNotDeleteAdditionalFiles -AsBool
        if ($addDoNotDeleteRule) {
            $argumentArray += "-enableRule:DoNotDeleteRule"
        }

        $process = Run-MSDeploy $argumentArray
        return $process
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}

function Compute-ParameterFile {
    [CmdletBinding()]
    param(
        [string] $packageParameterFile,
        [string] $packagePath
    )

    Trace-VstsEnteringInvocation $MyInvocation
    try {
        if (-not($packageParameterFile) -or $packageParameterFile -eq $env:SYSTEM_DEFAULTWORKINGDIRECTORY) {
            $packageParameterFile = [System.IO.Path]::ChangeExtension($packagePath, ".SetParameters.xml")
            Write-Verbose "Compute path of package's parameters file: '$packageParameterFile'"
        }
        return $packageParameterFile
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}

function Run-MSDeploy {
    [CmdletBinding()]
    param(
        [string[]] $argumentArray
    )

    Trace-VstsEnteringInvocation $MyInvocation
    try {
        $arguments = ""
        foreach ($arg in $argumentArray) {
            $arguments += $arg + " "
        }
        [string] $additionalParameters = Get-VstsInput -Name AdditionalParameters
        $arguments += $additionalParameters

        Write-Verbose "Argument list: $arguments"

        $msdeploy = Find-MSDeploy
        $process = Start-Process -FilePath $msdeploy -ArgumentList $arguments -Wait -NoNewWindow -PassThru
        return $process
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}

function Find-MSDeploy {
    [CmdletBinding()]
    param()

    Trace-VstsEnteringInvocation $MyInvocation
    try {
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
        Write-Verbose "Found MSDeploy.exe at: '$msdeploy'"
        return $msdeploy
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}

function Get-DestinationParameter {
    [CmdletBinding()]
    param(
        [string] $serverName
    )

    Trace-VstsEnteringInvocation $MyInvocation
    try {
        $PublishUrl = "http://$Server/MsDeployAgentService"
        $destinationParameter = "-dest:auto,computerName='$PublishUrl'"

        [string]$adminUserName = Get-VstsInput -Name AdminUserName
        [string]$adminPassword = Get-VstsInput -Name AdminPassword

        if($adminUserName -ne "" -and $adminPassword -ne "") {
            Write-Verbose "Use identity '$adminUserName' to run MSDeploy"
            $destinationParameter ="$destinationParameter,userName=""$adminUserName"",password=""$adminPassword"""
        }
        else {
            Write-Verbose "Use agent's identity to run MSDeploy"
        }
        return $destinationParameter
    }
    finally {
        Trace-VstsLeavingInvocation $MyInvocation
    }
}