
function DeployDacPac() {
    param(
        [string]$sqlVersion,
        [string]$dacpacFilePath,
        [string]$xmlPublishFilePath,
        [string]$schemaToExclude
    )
    try {
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
        Write-Host "currentDir $currentDir"

        $sqlPackageDir = [System.IO.Path]::Combine($currentDir, $sqlVersion, "bin")

        Write-Host "sqlPackageDir $sqlPackageDir"

        $sqlPackagePath = [System.IO.Path]::Combine($sqlPackageDir, "sqlpackage.exe")

        Write-Host "sqlPackagePath $sqlPackagePath"

        $args = @("/Action:Publish", 
            "/SourceFile:`"$dacpacFilePath`"",
            "/Profile:`"$xmlPublishFilePath`"")
          
        if ($schemaToExclude) {
            $args += "/p:AdditionalDeploymentContributors=AgileSqlClub.DeploymentFilterContributor"
            $args += "/p:AdditionalDeploymentContributorArguments=SqlPackageFilter=IgnoreSchema($schemaToExclude)"
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

DeployDacPac SQL2019 `
C:\TeamProjects\MAF.DAP\dap\src\MAF.DAP.Database.Declaration\bin\Release\MAF.DAP.Database.Declaration.dacpac `
C:\TeamProjects\MAF.DAP\dap\src\MAF.DAP.Database.Declaration\bin\Release\MAF.DAP.Database.Declaration.publish.xml `
RefMaf
