[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation
try {
    [string]$serverName = Get-VstsInput -Name serverName -Require
    [string]$databaseName = Get-VstsInput -Name databaseName -Require
    [string]$dacpacFilePath = Get-VstsInput -Name dacpacFilePath -Require
    [string]$xmlPublishFilePath = Get-VstsInput -Name xmlPublishFilePath
    [string]$schemaToExclude = Get-VstsInput -Name schemaToExclude

    $user=[Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Debug "Deploying as  $user.Name"
    Write-Debug "Server: $serverName"
    Write-Debug "Database: $databaseName"
    Write-Debug "DACPAC file: $dacpacFilePath"
    if($xmlPublishFilePath -ne $null) {
        Write-Debug "Publish profile file: $xmlPublishFilePath"
    }
    if($schemaToExclude -ne $null) {
        Write-Debug "Schema to exclude: $schemaToExclude"
    }

    Write-Host "Deploying database $databaseName to server $serverName"
    
    $currentDir = (Get-Item -Path ".\" -Verbose).FullName
    $sqlPackageDir = [System.IO.Path]::Combine($currentDir, "bin")
    $sqlPackagePath = [System.IO.Path]::Combine($sqlPackageDir, "sqlpackage.exe")

    $args = @("/Action:Publish", 
            "/SourceFile:$dacpacFilePath",
            "/TargetConnectionString:Data Source=$SqlServer;Integrated Security=true;Initial Catalog=$databaseName")

    if($xmlPublishFilePath -ne $null) {
        $args += "/Profile:$xmlPublishFilePath"
    }      
          
    if($schemaToExclude -ne $null) {
        $args += "/p:AdditionalDeploymentContributors=AgileSqlClub.DeploymentFilterContributor"
        $args += "/p:AdditionalDeploymentContributorArguments=SqlPackageFilter=IgnoreSchema($schemaToExclude)"
    }   
    
    &$sqlPackagePath $args 2>&1

} catch  [System.Exception] {
    Write-Host "##vso[task.logissue type=error;] DacpacDeploy Error: $_"
    Write-Host "##vso[task.complete result=Failed]Failed"
} finally {
    Write-Host "Ending DacpacDeploy task"
}
