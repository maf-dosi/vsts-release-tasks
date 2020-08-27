[CmdletBinding()]
param()
Trace-VstsEnteringInvocation $MyInvocation

function DeployDacPac() {
    try {
        $sqlVersion = "SQL2019"
        [string]$dacpacFilePath = Get-VstsInput -Name dacpacFilePath -Require
        [string]$xmlPublishFilePath = Get-VstsInput -Name xmlPublishFilePath
        [string]$schemaToExclude = Get-VstsInput -Name schemaToExclude

        $user = [Security.Principal.WindowsIdentity]::GetCurrent()
        Write-Host "Deploying as" $user.Name

        Write-Host "DACPAC file: $dacpacFilePath"
        if (-not($xmlPublishFilePath) -or $xmlPublishFilePath -eq $env:SYSTEM_DEFAULTWORKINGDIRECTORY) {
            $xmlPublishFilePath = [System.IO.Path]::GetDirectoryName($dacpacFilePath) + "\" + [System.IO.Path]::GetFileNameWithoutExtension($dacpacFilePath) + ".publish.xml"
        }
        Write-Host "Publish profile file: $xmlPublishFilePath"
        Write-Host "Reading connection information from the publish profile"
        [xml]$publishProfile = Get-Content -Path $xmlPublishFilePath
        Write-Host "Target connection string:" $publishProfile.Project.PropertyGroup.TargetConnectionString
        Write-Host "Database name:" $publishProfile.Project.PropertyGroup.TargetDatabaseName
        if ($schemaToExclude) {
            Write-Debug "Schema to exclude: $schemaToExclude"
        }

        $currentDir = (Get-Item -Path ".\" -Verbose).FullName
        $sqlPackageDir = [System.IO.Path]::Combine($currentDir, $sqlVersion, "bin")
        $sqlPackagePath = [System.IO.Path]::Combine($sqlPackageDir, "sqlpackage.exe")

        $args = @("/Action:Publish", 
            "/SourceFile:`"$dacpacFilePath`"",
            "/Profile:`"$xmlPublishFilePath`"")
          
        if ($schemaToExclude) {
            $args += "/p:AdditionalDeploymentContributors=AgileSqlClub.DeploymentFilterContributor"
            $args += "/p:AdditionalDeploymentContributorArguments=""SqlPackageFilter=IgnoreSchema($schemaToExclude)"""
        }
        Write-Debug "Calling $sqlPackagePath with $args"
        $ErrorActionPreference = 'Continue' 
        Invoke-Expression "& '$sqlPackagePath' --% $args" -ErrorVariable errors | ForEach-Object {
            if ($_ -is [System.Management.Automation.ErrorRecord]) {
                Write-Error $_
            }
            else {
                Write-Host $_
            }
        }
        foreach ($errorMsg in $errors) {
            Write-Error $errorMsg
        }
        $ErrorActionPreference = 'Stop'
        if ($LASTEXITCODE -ne 0) {
            throw
        }
    } 
    catch  [System.Exception] {
        Write-Host "##vso[task.logissue type=error;] DacpacDeploy Error"
        Write-Host "##vso[task.complete result=Failed]Failed"
    }
    finally {
        Write-Host "Ending DacpacDeploy task"
    }
}

DeployDacPac
