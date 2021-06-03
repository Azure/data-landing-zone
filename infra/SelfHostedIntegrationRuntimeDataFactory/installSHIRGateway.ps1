[CmdletBinding()]
param (
	[Parameter(Mandatory = $true)]
	[ValidateNotNullOrEmpty()]
	[String]
	$gatewayKey,

	[Parameter(DontShow)]
	[String]
	$gatewayUri = "https://go.microsoft.com/fwlink/?linkid=839822"
)

# Define variables
$gatewayPath = "$PWD\gateway.msi"
$logLoc = "$env:SystemDrive\WindowsAzure\Logs\Plugins\Microsoft.Compute.CustomScriptExtension\"
$logPath = "$logLoc\tracelog.log"

function New-Error([string] $msg) {
	try {
		throw $msg
	}
	catch {
		$stack = $_.ScriptStackTrace
		Trace-Log "DMDTTP is failed: $msg`nStack:`n$stack"
	}
	throw $msg
}

function Trace-Log([string] $msg) {
	$now = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
	try {
		"${now} $msg`n" | Out-File $logPath -Append
	}
	catch {
		Write-Error "Error when writing trace log"
	}
}

function Invoke-Process([string] $process, [string] $arguments) {
	Write-Verbose "Run-Process: $process $arguments"

	$errorFile = "$env:tmp\tmp$pid.err"
	$outFile = "$env:tmp\tmp$pid.out"
	"" | Out-File $outFile
	"" | Out-File $errorFile

	$errVariable = ""

	if ([string]::IsNullOrEmpty($arguments)) {
		$proc = Start-Process -FilePath $process -Wait -Passthru -NoNewWindow `
			-RedirectStandardError $errorFile -RedirectStandardOutput $outFile -ErrorVariable errVariable
	}
	else {
		$proc = Start-Process -FilePath $process -ArgumentList $arguments -Wait -Passthru -NoNewWindow `
			-RedirectStandardError $errorFile -RedirectStandardOutput $outFile -ErrorVariable errVariable
	}

	$errContent = [string] (Get-Content -Path $errorFile -Delimiter "!!!DoesNotExist!!!")
	$outContent = [string] (Get-Content -Path $outFile -Delimiter "!!!DoesNotExist!!!")

	Remove-Item $errorFile
	Remove-Item $outFile

	if ($proc.ExitCode -ne 0 -or $errVariable -ne "") {
		New-Error "Failed to run process: exitCode=$($proc.ExitCode), errVariable=$errVariable, errContent=$errContent, outContent=$outContent."
	}

	Trace-Log "Run-Process: ExitCode=$($proc.ExitCode), output=$outContent"

	if ([string]::IsNullOrEmpty($outContent)) {
		return $outContent
	}

	return $outContent.Trim()
}

function Get-Gateway([string] $url, [string] $gatewayPath) {
	try {
		$ErrorActionPreference = "Stop";
		$client = New-Object System.Net.WebClient
		$client.DownloadFile($url, $gatewayPath)
		Trace-Log "Download gateway successfully. Gateway loc: ${gatewayPath}"
	}
	catch {
		Trace-Log "Fail to download gateway msi"
		Trace-Log $_.Exception.ToString()
		throw
	}
}

function Install-Gateway([string] $gatewayPath) {
	if ([string]::IsNullOrEmpty($gatewayPath)) {
		New-Error "Gateway path is not specified"
	}
	if (!(Test-Path -Path $gatewayPath)) {
		New-Error "Invalid gateway path: ${gatewayPath}"
	}
	Trace-Log "Start Gateway installation"
	Invoke-Process "msiexec.exe" "/i gateway.msi INSTALLTYPE=AzureTemplate /quiet /norestart"
	Start-Sleep -Seconds 30
	Trace-Log "Installation of gateway is successful"
}

function Get-RegistryProperty([string] $keyPath, [string] $property) {
	Trace-Log "Get-RegistryProperty: Get $property from $keyPath"
	if (! (Test-Path $keyPath)) {
		Trace-Log "Get-RegistryProperty: $keyPath does not exist"
	}

	$keyReg = Get-Item $keyPath
	if (! ($keyReg.Property -contains $property)) {
		Trace-Log "Get-RegistryProperty: $property does not exist"
		return ""
	}
	return $keyReg.GetValue($property)
}

function Get-InstalledFilePath() {
	$filePath = Get-RegistryProperty "hklm:\Software\Microsoft\DataTransfer\DataManagementGateway\ConfigurationManager" "DiacmdPath"
	if ([string]::IsNullOrEmpty($filePath)) {
		New-Error "Get-InstalledFilePath: Cannot find installed File Path"
	}
	Trace-Log "Gateway installation file: $filePath"
	return $filePath
}

function Register-Gateway([string] $instanceKey) {
	Trace-Log "Register Agent"
	$filePath = Get-InstalledFilePath
	Invoke-Process $filePath "-era 8060"
	Invoke-Process $filePath "-k $instanceKey"
	Trace-Log "Agent registration is successful!"
}

# Init log settings
if (!(Test-Path($logLoc))) {
	New-Item -Path $logLoc -ItemType Directory -Force
}
"Start to excute gatewayInstall.ps1. `n" | Out-File $logPath
Trace-Log "Log file: $logLoc"
Trace-Log "Gateway download fw link: ${gatewayUri}"
Trace-Log "Gateway download location: ${gatewayPath}"

Get-Gateway $gatewayUri $gatewayPath
Install-Gateway $gatewayPath
Register-Gateway $gatewayKey
