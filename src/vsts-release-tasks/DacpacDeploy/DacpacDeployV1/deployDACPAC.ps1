[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation
try {
    [string]$dacpacFilePath = Get-VstsInput -Name dacpacFilePath -Require
    [string]$xmlPublishFilePath = Get-VstsInput -Name xmlPublishFilePath
    [string]$schemaToExclude = Get-VstsInput -Name schemaToExclude
    [string]$blockOnDropDataAsString = Get-VstsInput -Name blockOnDropDataAsString

    $user=[Security.Principal.WindowsIdentity]::GetCurrent()
    Write-Debug "Deploying as  $user.Name"

    Write-Debug "DACPAC file: $dacpacFilePath"
    if(-not($xmlPublishFilePath) -or $xmlPublishFilePath -eq $env:SYSTEM_DEFAULTWORKINGDIRECTORY) {
        $xmlPublishFilePath =  [System.IO.Path]::GetDirectoryName($dacpacFilePath) + "\" + [System.IO.Path]::GetFileNameWithoutExtension($dacpacFilePath) + ".publish.xml"
    }
    Write-Debug "Publish profile file: $xmlPublishFilePath"
    Write-Debug "Reading connection information from the publish profile"
    [xml]$publishProfile = Get-Content -Path $xmlPublishFilePath
    Write-Debug "Target connection string: $publishProfile.Project.PropertyGroup.TargetConnectionString"
    Write-Debug "Database name: $publishProfile.Project.PropertyGroup.TargetDatabaseName"
    if($schemaToExclude) {
        Write-Debug "Schema to exclude: $schemaToExclude"
    }
    Write-Debug "Block on data loss : $blockOnDropDataAsString"

    $currentDir = (Get-Item -Path ".\" -Verbose).FullName
    $sqlPackageDir = [System.IO.Path]::Combine($currentDir, "bin")
    $sqlPackagePath = [System.IO.Path]::Combine($sqlPackageDir, "sqlpackage.exe")

    $args = @("/Action:Publish", 
            "/SourceFile:$dacpacFilePath",
            "/Profile:$xmlPublishFilePath")
          
    if($schemaToExclude) {
        $args += "/p:AdditionalDeploymentContributors=AgileSqlClub.DeploymentFilterContributor"
        $args += "/p:AdditionalDeploymentContributorArguments=SqlPackageFilter=IgnoreSchema($schemaToExclude)"
    }   
    if($blockOnDropDataAsString){
        $blockOnDropData = $blockOnDropDataAsString -ne 'false'
        $args += "/p:BlockOnPossibleDataLoss=$blockOnDropData"
    }

    &$sqlPackagePath $args 2>&1

} catch  [System.Exception] {
    Write-Host "##vso[task.logissue type=error;] DacpacDeploy Error: $_"
    Write-Host "##vso[task.complete result=Failed]Failed"
} finally {
    Write-Host "Ending DacpacDeploy task"
}
