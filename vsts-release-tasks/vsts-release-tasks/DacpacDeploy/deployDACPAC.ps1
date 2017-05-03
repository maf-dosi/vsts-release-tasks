param(
    [string] [Parameter(Mandatory = $true)]
    $serverName,    
    [string] [Parameter(Mandatory = $true)]
    $databaseName,    
    [string] [Parameter(Mandatory = $true)]
    $dacpacFilePath,
    [string] [Parameter(Mandatory = $false)]
    $xmlPublishFilePath
)

$user=[Security.Principal.WindowsIdentity]::GetCurrent()
Write-Host "Deploying as " $user.Name
$connectionString="Data Source=$serverName;Integrated Security=True;"

try {
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
    Write-Host "Path of Microsoft.SqlServer.Dac.dll: " $dacDllPath

	Add-Type -Path "$dacDllPath\\Microsoft.SqlServer.Dac.dll"
	$dacService = New-Object Microsoft.SqlServer.Dac.DacServices $connectionString
    Register-ObjectEvent -in $dacService -eventname Message -source "msg" -action { out-host -in $Event.SourceArgs[1].Message.Message } | Out-Null

	$dacPackage = [Microsoft.SqlServer.Dac.DacPackage]::Load($dacpacFilePath)

    if($xmlPublishFilePath){
        $dacProfile = [Microsoft.SqlServer.Dac.DacProfile]::Load($xmlPublishFilePath)
        $deployOptions=$dacProfile.DeployOptions
    } else {
        $deployOptions = $null
    }

    Write-Host "Deploying database $databaseName to server $serverName"
    try{
    $dacService.Deploy($dacPackage, $databaseName, $true, $deployOptions) 
    } catch [Microsoft.SqlServer.Dac.DacServicesException] {
        Resolve-Error -Error $_
        throw ('Deployment failed: ''{0}'' Reason: ''{1}'' ''{2}''' -f $_.Exception.Message, $_.Exception.InnerException.Message, $_.Exception.InnerException.InnerException.Message)
    }
    Unregister-Event -source "msg" 
} catch  [System.Exception] {
    Write-Host "##vso[task.logissue type=error;] DacpacDeploy Error: $_.Message" 
} finally {	
}
Write-Host "Ending DacpacDeploy task"