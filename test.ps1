    Write-Host '`n`nPSVersion`n`n'
    $PSVersionTable |
        Out-Host

    Write-Host '`n`nMODULES`n`n'
    Get-Module -ListAvailable |
        Select Name,
               Version,
               Path |
        Sort Name |
        Out-Host

    Write-Host '`n`nENV`n`n'
    Get-ChildItem ENV: |
        Out-Host

    Write-Host '`n`nVARIABLES`n`n'

    Get-Variable |
        Out-Host

    Write-Host '`n`nPowerShellGet`n`n'
    Get-Command -Module PowerShellGet |
        Select -ExpandProperty Name |
        Sort |
        Out-Host