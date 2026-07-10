param(
  [Parameter(Mandatory = $true)]
  [string]$RegistrationToken
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

$agentInstaller = Join-Path $PSScriptRoot 'RDAgent.msi'
$bootLoaderInstaller = Join-Path $PSScriptRoot 'RDBootLoader.msi'

if (-not (Test-Path $agentInstaller)) {
  throw 'RDAgent.msi was not downloaded by the Custom Script extension.'
}

if (-not (Test-Path $bootLoaderInstaller)) {
  throw 'RDBootLoader.msi was not downloaded by the Custom Script extension.'
}

$agentProcess = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', $agentInstaller, '/qn', "REGISTRATIONTOKEN=$RegistrationToken") -Wait -PassThru
if ($agentProcess.ExitCode -notin @(0, 3010)) {
  throw "Azure Virtual Desktop agent installation failed with exit code $($agentProcess.ExitCode)."
}

$bootLoaderProcess = Start-Process -FilePath 'msiexec.exe' -ArgumentList @('/i', $bootLoaderInstaller, '/qn') -Wait -PassThru
if ($bootLoaderProcess.ExitCode -notin @(0, 3010)) {
  throw "Azure Virtual Desktop boot loader installation failed with exit code $($bootLoaderProcess.ExitCode)."
}