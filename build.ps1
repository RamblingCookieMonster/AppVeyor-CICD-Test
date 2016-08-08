# Grab nuget bits, install modules, set build variables, start build.
Get-PackageProvider -Name NuGet -ForceBootstrap | Out-Null

Install-Module PSDepend -Force
Invoke-PSDepend -Force -verbose
#Set-BuildEnvironment

# For PS2, after installing with PS5.
Move-Item C:\temp\pester\*\* -Destination C:\temp\pester -force

Invoke-psake .\psake.ps1
exit ( [int]( -not $psake.build_success ) )