
param(
	[string][Parameter(Mandatory=$true)] $Zippath, 
	[string][Parameter(Mandatory=$true)] $Servername,
	[string] $Parameterspath
)

Write-Host "Starting IISDeploy task"


try {

	Write-Verbose "Zippath : $Zippath"
	Write-Verbose "Servername : $Servername"
	Write-Verbose "Parameterspath : $Parameterspath"


		function DeployWebsite($Package, $Server, $paramfile) {
			

			$MSDeployKey = 'HKLM:\SOFTWARE\Microsoft\IIS Extensions\MSDeploy\3' 
			if(!(Test-Path $MSDeployKey)) { 
			throw "Could not find MSDeploy. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
			} 

			$InstallPath = (Get-ItemProperty $MSDeployKey).InstallPath 
			if(!$InstallPath -or !(Test-Path $InstallPath)) { 
			throw "Could not find MSDeploy. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
			} 

			$msdeploy = Join-Path $InstallPath "msdeploy.exe" 
			if(!(Test-Path $MSDeploy)) { 
			throw "Could not find MSDeploy. Use Web Platform Installer to install the 'Web Deployment Tool' and re-run this command" 
			}

			$PublishUrl = "https://$Server/MsDeployAgentService"
			

			# DEPLOY!
			Write-Host "Deploying package to $PublishUrl"
	
			$arguments = [string[]]@(
				"-verb:sync",
				"-source:package='$Package'",
				"-dest:auto,computerName='$PublishUrl'",
				"-setParamFile:$paramfile")
			
			#Write-Host "Start-Process $msdeploy -ArgumentList $arguments -NoNewWindow -Wait"
			#Start-Process "$msdeploy" -ArgumentList "$arguments" -NoNewWindow -Wait

Write-Host "Invoke-Expression '&"$msdeploy" -verb:sync "-source:package=$Package" "-dest:auto,computerName=$PublishUrl" -setParamFile:$paramfile'"
			".\$msdeploy" -verb:sync -source:package="$Package" -dest:auto,computerName="$PublishUrl" -setParamFile:$paramfile
			
		}

		DeployWebsite -Package $Zippath -Server $Servername -paramfile $Parameterspath

} catch {

	Write-Host “##vso[task.logissue type=error;] MsDeploy Error”

} finally {
	
}

Write-Host "Ending IISDeploy task"