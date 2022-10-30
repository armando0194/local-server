
function Get-ScriptDirectory
{
	[OutputType([string])]
	param ()
	if ($null -ne $hostinvocation)
	{
		Split-Path $hostinvocation.MyCommand.path
	}
	else
	{
		Split-Path $script:MyInvocation.MyCommand.Path
	}
}

$scriptPath = (Get-ScriptDirectory);
$configFilepath = (get-item $scriptPath ).parent.FullName + "\config.json"

if (!(Test-Path -Path $configFilepath -PathType Leaf)) {
  Write-Host $configFilepath "does not exist"
  return 
}

Write-Host "Using config file in '$configFilepath'" 

$file = "C:\Windows\System32\drivers\etc\hosts"
$config = Get-Content -Path $configFilepath | ConvertFrom-Json
$hostfile = Get-Content $file

Write-Host "Reseting proxy" 
netsh interface portproxy reset all | Out-Null

foreach ($server in $config.servers)
{
  Write-Host "Setting server: '$($server.ip)'" 

  foreach ($service in $server.services) {
    Write-Host "-  Setting service: '$($service.name)'"
    $hostfile += "$($service.listenAddress)     $($service.hostname) `n"
    netsh interface portproxy add v4tov4 listenport=80 listenaddress=$($service.listenAddress) connectport=$($service.connectPort) connectaddress=$($server.ip) | Out-Null
  }
}

Set-Content -Path $file -Value $hostfile -Force
Write-Host "Done" 