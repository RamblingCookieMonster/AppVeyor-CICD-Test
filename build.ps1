# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Install-Module PSDepend -Force
Invoke-PSDepend -Force -verbose
#Set-BuildEnvironment

Invoke-psake .\psake.ps1
exit ( [int]( -not $psake.build_success ) )