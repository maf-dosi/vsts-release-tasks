param(
	[string]$webTestAssembly,
	[string]$testSettings,
	[string]$testRunTitle,
	[string]$platform,
	[string]$configuration,
	[string]$publishRunAttachments
)

Write-Verbose 'Start'
Write-Verbose "webTestAssembly = $webTestAssembly"
Write-Verbose "testSettings = $testSettings"

import-module "Microsoft.TeamFoundation.DistributedTask.Task.Internal"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.Common"
import-module "Microsoft.TeamFoundation.DistributedTask.Task.TestResults"

Function CmdletHasMember($memberName) {
	$publishParameters = (gcm Publish-TestResults).Parameters.Keys.Contains($memberName)
	return $publishParameters
}

if (!$webTestAssembly)
{
	throw (Get-LocalizedString -Key "No test assembly specified. Provide a test assembly parameter and try again.")
}

$sourcesDirectory = Get-TaskVariable -Context $distributedTaskContext -Name "Build.SourcesDirectory"
if(!$sourcesDirectory)
{
	# For RM, look for the test assemblies under the release directory.
	$sourcesDirectory = Get-TaskVariable -Context $distributedTaskContext -Name "Agent.ReleaseDirectory"
}

if(!$sourcesDirectory)
{
	# If there is still no sources directory, error out immediately.
	throw (Get-LocalizedString -Key "No source directory found.")
}

$webTestAssemblyFiles = @()
# check for solution pattern
if ($webTestAssembly.Contains("*") -Or $webTestAssembly.Contains("?"))
{
	Write-Verbose "Pattern found in solution parameter. Calling Find-Files."
	Write-Verbose "Calling Find-Files with pattern: $webTestAssembly"
	$webTestAssemblyFiles = Find-Files -SearchPattern $webTestAssembly -RootFolder $sourcesDirectory
	Write-Verbose "Found files: $webTestAssemblyFiles"
}
else
{
	Write-Verbose "No Pattern found in solution parameter."
	$webTestAssembly = $webTestAssembly.Replace(';;', "`0") # Barrowed from Legacy File Handler
	foreach ($assembly in $webTestAssembly.Split(";"))
	{
		$webTestAssemblyFiles += ,($assembly.Replace("`0",";"))
	}
}

$XMLfile = NEW-OBJECT XML
$XMLfile.Load($testSettings)

$nsmgr = new-object System.Xml.XmlNamespaceManager $XMLfile.NameTable
$nsmgr.AddNamespace("x","http://microsoft.com/schemas/VisualStudio/TeamTest/2010")

$xmlElt = $XMLfile.TestSettings.SelectSingleNode("./x:NamingScheme",$nsmgr)

if (!($xmlElt))
{
	$xmlElt = $XMLfile.CreateElement("NamingScheme", $nsmgr.LookupNamespace("x"))
	$XMLFile.LastChild.AppendChild($xmlElt) | Out-Null
}

$xmlAtt = $XMLfile.CreateAttribute("baseName")
$xmlAtt.Value = "webtests"
$xmlElt.Attributes.Append($xmlAtt) | Out-Null
$xmlAtt = $XMLfile.CreateAttribute("appendTimeStamp")
$xmlAtt.Value = "false"
$xmlElt.Attributes.Append($xmlAtt) | Out-Null
$xmlAtt = $XMLfile.CreateAttribute("useDefault")
$xmlAtt.Value = "false"
$xmlElt.Attributes.Append($xmlAtt) | Out-Null

$XMLFile.save($testSettings)

$tool = Join-Path $env:VS140COMNTOOLS "..\IDE\MSTest.exe"
$resultFile = Join-Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY  "webtests.trx"
if(Test-Path $resultFile)
{
	Remove-Item $resultFile -force
}
#$include = "*.webtest"
#$web_tests = get-ChildItem -Path $paths -Recurse -Include $include
foreach ($item in $webTestAssemblyFiles)
{
	$args += "/TestContainer:$item "
}

& $tool $args /resultsfile:$resultFile /testsettings:$testSettings

$last = $LASTEXITCODE

$publishResultsOption = Convert-String $publishRunAttachments Boolean

if($resultFile)
{
	# Remove the below hack once the min agent version is updated to S91 or above
	$runTitleMemberExists = CmdletHasMember "RunTitle"
	$publishRunLevelAttachmentsExists = CmdletHasMember "PublishRunLevelAttachments"
	if($runTitleMemberExists)
	{
		if($publishRunLevelAttachmentsExists)
		{
			Publish-TestResults -Context $distributedTaskContext -TestResultsFiles $resultFile -TestRunner "VSTest" -Platform $platform -Configuration $configuration -RunTitle $testRunTitle -PublishRunLevelAttachments $publishResultsOption
		}
		else
		{
			if(!$publishResultsOption)
			{
				Write-Warning (Get-LocalizedString -Key "Update the agent to try out the '{0}' feature." -ArgumentList "opt in/out of publishing test run attachments")
			}
			Publish-TestResults -Context $distributedTaskContext -TestResultsFiles $resultFile -TestRunner "VSTest" -Platform $platform -Configuration $configuration -RunTitle $testRunTitle
		}
	}
	else
	{
		if($testRunTitle)
		{
			Write-Warning (Get-LocalizedString -Key "Update the agent to try out the '{0}' feature." -ArgumentList "custom run title")
		}

		if($publishRunLevelAttachmentsExists)
		{
			Publish-TestResults -Context $distributedTaskContext -TestResultsFiles $resultFile -TestRunner "VSTest" -Platform $platform -Configuration $configuration -PublishRunLevelAttachments $publishResultsOption
		}
		else
		{
			if(!$publishResultsOption)
			{
				Write-Warning (Get-LocalizedString -Key "Update the agent to try out the '{0}' feature." -ArgumentList "opt in/out of publishing test run attachments")
			}
			Publish-TestResults -Context $distributedTaskContext -TestResultsFiles $resultFile -TestRunner "VSTest" -Platform $platform -Configuration $configuration
		}
	}
}
else
{
	Write-Host "##vso[task.logissue type=warning;code=002003;]"
	Write-Warning (Get-LocalizedString -Key "No results found to publish.")
}

if($last -ne 0)
{
	throw "Error while running tests"
}

Write-Verbose "End"
