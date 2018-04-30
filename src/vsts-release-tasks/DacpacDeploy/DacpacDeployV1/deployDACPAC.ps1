[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation
try {
    [string]$serverName = Get-VstsInput -Name serverName -Require
    [string]$databaseName = Get-VstsInput -Name databaseName -Require
    [string]$dacpacFilePath = Get-VstsInput -Name dacpacFilePath
    [string]$xmlPublishFilePath = Get-VstsInput -Name xmlPublishFilePath
    [string]$blockOnDropDataAsString = Get-VstsInput -Name blockOnDropDataAsString

    $user=[Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Debug "Deploying as  $user.Name"
    Write-Debug "Server: $serverName"
    Write-Debug "Database: $databaseName"
    Write-Debug "DACPAC file: $dacpacFilePath"
    Write-Debug "Publish file: $xmlPublishFilePath"
    Write-Debug "Block on data loss : $blockOnDropDataAsString"
    $connectionString="Data Source=$serverName;Integrated Security=True;"

    $dacDllPath = $null
    for($ver=110; $ver -lt 200; $ver+=10) # DACPAC ships with SQL Server 2008 and above
    {
        $path = "C:\\Program Files (x86)\\Microsoft SQL Server\\$ver\\DAC\\bin"
        if(Get-Item -Path $path -ErrorAction SilentlyContinue)
        {
            $dacDllPath = $path
        }
        $path = "C:\\Program Files\\Microsoft SQL Server\\$ver\\DAC\\bin"
        if(Get-Item -Path $path -ErrorAction SilentlyContinue)
        {
            $dacDllPath = $path
        }
    }

    if(!$dacDllPath)
    {
        Write-Error "DACPAC runtime not found, make sure the task executes on a machine with SQL Server tools installed"
        exit
    }
    Write-Debug "Path of Microsoft.SqlServer.Dac.dll: '$dacDllPath'"

    Add-Type -Path "$dacDllPath\\Microsoft.SqlServer.Dac.dll"
    $dacService = New-Object Microsoft.SqlServer.Dac.DacServices $connectionString
    Register-ObjectEvent -in $dacService -eventname Message -source "msg" -action { out-host -in $Event.SourceArgs[1].Message.Message } | Out-Null

    $dacPackage = [Microsoft.SqlServer.Dac.DacPackage]::Load($dacpacFilePath)

    if($xmlPublishFilePath -and $xmlPublishFilePath -ne $env:SYSTEM_DEFAULTWORKINGDIRECTORY){
        $dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($xmlPublishFilePath)
        $deployOptions=$dacProfile.DeployOptions
    } else {
        $deployOptions = $null
    }

    if($blockOnDropDataAsString){
        if($deployOptions -eq $null){
            $deployOptions = New-Object Microsoft.SqlServer.Dac.DacDeployOptions
        }
        $deployOptions.BlockOnPossibleDataLoss = $blockOnDropDataAsString -ne 'false'
    }

    Write-Host "Deploying database $databaseName to server $serverName"
    try{
        $dacService.Deploy($dacPackage, $databaseName, $true, $deployOptions)
    } catch [Microsoft.SqlServer.Dac.DacServicesException] {
        throw ('Deployment failed: ''{0}'' Reason: ''{1}'' ''{2}''' -f $_.Exception.Message, $_.Exception.InnerException.Message, $_.Exception.InnerException.InnerException.Message)
    }
    Unregister-Event -source "msg"
} catch  [System.Exception] {
    Write-Host "##vso[task.logissue type=error;] DacpacDeploy Error: $_"
    Write-Host "##vso[task.complete result=Failed]Failed"
} finally {
    Write-Host "Ending DacpacDeploy task"
}
