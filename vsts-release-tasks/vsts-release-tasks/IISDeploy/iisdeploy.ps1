[CmdletBinding()]
param(
	[string][Parameter(Mandatory=$true)] $ZipPath, 
	[string][Parameter(Mandatory=$true)] $ServerName,
	[bool] $DoNotDeleteAdditionalFiles,
	[string] $ParametersPath,
	[string] $AdditionalParameters
)

function Deploy-Website($Package, $Server, $ParamFile, $addDoNotDeleteRule, $additionalParameters) {
	Write-Verbose "Deploy-Website parameters:"
	Write-Verbose "Package: $Package"
	Write-Verbose "Server: $Server"
	Write-Verbose "ParamFile: $ParamFile"
	Write-Verbose "addDoNotDeleteRule: $addDoNotDeleteRule"
	Write-Verbose "additionalParameters: $additionalParameters"

	$MSDeployKey = 'HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3' 
	if(!(Test-Path $MSDeployKey)) { 
		throw "Could not find MSDeploy path. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
	} 

	$InstallPath = (Get-ItemProperty $MSDeployKey).InstallPath 
	if(!$InstallPath -or !(Test-Path $InstallPath)) { 
		throw "Could not find MSDeploy at '$InstallPath'. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
	} 

	$msdeploy = Join-Path $InstallPath "msdeploy.exe" 
	if(!(Test-Path $MSDeploy)) { 
		throw "Could not find MSDeploy. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
	}

	$PublishUrl = "http://$Server/MsDeployAgentService"
	
	# DEPLOY!
	$argumentArray = [string[]]@(
		"-verb:sync",
		"-source:package='$Package'",
		"-dest:auto,computerName='$PublishUrl'",
		"-setParamFile:$ParamFile")
	
	if($addDoNotDeleteRule) {
		$argumentArray += "-enableRule:DoNotDeleteRule"
	}

	$arguments = ""
	foreach($arg in $argumentArray){
		$arguments += $arg + " "
	}
	$arguments += $additionalParameters

	Write-Host "Deploying package to $PublishUrl"
	Write-Verbose "Argument list: $arguments"
	$process = Start-Process -FilePath $msdeploy -ArgumentList $arguments -Wait -NoNewWindow -PassThru
	return $process
}

Write-Host "Starting IISDeploy task"

try {
	Write-Verbose "Task parameters:"
	Write-Verbose "ZipPath: $ZipPath"
	Write-Verbose "ServerName: $ServerName"
	Write-Verbose "DoNotDeleteAdditionalFiles: $DoNotDeleteAdditionalFiles"
	Write-Verbose "ParametersPath: $ParametersPath"
	Write-Verbose "AdditionalParameters: $AdditionalParameters"

	if($ZipPath -notmatch '\.zip'){
		throw "The package should be a .zip file"
	}
	
	if(-not($ParametersPath)){
		$ParametersPath = [System.IO.Path]::ChangeExtension($ZipPath, ".SetParameters.xml")
		Write-Verbose "Compute ParametersPath: $ParametersPath"
	}

	$process = Deploy-Website -Package $ZipPath -Server $ServerName -ParamFile $ParametersPath -addDoNotDeleteRule $DoNotDeleteAdditionalFiles -additionalParameters $AdditionalParameters
	if($process.ExitCode -ne 0){
		throw "Errors when running MSDeploy (exit code = $($process.ExitCode))"
	}
} catch {
	Write-Host "##vso[task.logissue type=error;] MsDeploy Error: $_"
} finally {	
}
Write-Host "Ending IISDeploy task"