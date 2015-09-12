# This script will invoke pester tests and deploy (I know, I know... do one thing...)
# It should invoke on PowerShell v2 and later
# We serialize XML results and pull them in appveyor.yml

#If Finalize is specified, we collect XML output, upload tests, and indicate build errors
param(
    [switch]$Finalize,
    [switch]$Test,
    [switch]$Deploy,
    [switch]$ConfigurePester,
    [string]$ProjectRoot = $ENV:APPVEYOR_BUILD_FOLDER
)

    if($ConfigurePester)
    {
        $PesterPath = @( (Get-Module Pester -ListAvailable).Path )[0]
        [Environment]::SetEnvironmentVariable("PesterPath", $PesterPath, "Machine")
        return
    }

#Initialize some variables, move to the project root
    $Timestamp = Get-date -uformat "%Y%m%d-%H%M%S"
    $PSVersion = $PSVersionTable.PSVersion.Major
    $TestFile = "TestResults_PS$PSVersion`_$TimeStamp.xml"

    $Address = "https://ci.appveyor.com/api/testresults/nunit/$($env:APPVEYOR_JOB_ID)"
    Set-Location $ProjectRoot

    $Verbose = @{}
    if($env:APPVEYOR_REPO_BRANCH -and $env:APPVEYOR_REPO_BRANCH -notlike "master")
    {
        $Verbose.add("Verbose",$True)
    }

#Run a test with the current version of PowerShell, upload results
    if($Test)
    {
        "`n`tSTATUS: Testing with PowerShell $PSVersion`n"

        #Load from path in env
        if($PSVersionTable.PSVersion.Major -le 4)
        {
            Import-Module $([Environment]::GetEnvironmentVariable("PesterPath","Machine"))
        }
        # cinst didn't seem to work??
        elseif(-not (Get-Module Pester -ListAvailable))
        {
            $null = Install-Module Pester -Force -Confirm:$False
            Import-Module Pester -force
        }
        #Module is there
        else
        {
            Import-Module Pester -force
        }

        Invoke-Pester @Verbose -Path "$ProjectRoot\Tests" -OutputFormat NUnitXml -OutputFile "$ProjectRoot\$TestFile" -PassThru |
            Export-Clixml -Path "$ProjectRoot\PesterResults_PS$PSVersion`_$Timestamp.xml"

        If($env:APPVEYOR_JOB_ID)
        {
            (New-Object 'System.Net.WebClient').UploadFile( $Address, "$ProjectRoot\$TestFile" )
        }

    }

#If finalize is specified, display errors and fail build if we ran into any
    If($Finalize)
    {
        #Show status...
            $AllFiles = Get-ChildItem -Path $ProjectRoot\PesterResults*.xml | Select -ExpandProperty FullName
            "`n`tSTATUS: Finalizing results`n"
            "COLLATING FILES:`n$($AllFiles | Out-String)"

        #What failed?
            $Results = @( Get-ChildItem -Path "$ProjectRoot\PesterResults_PS*.xml" | Import-Clixml )
            
            $FailedCount = $Results |
                Select -ExpandProperty FailedCount |
                Measure-Object -Sum |
                Select -ExpandProperty Sum
    
            if ($FailedCount -gt 0) {

                $FailedItems = $Results |
                    Select -ExpandProperty TestResult |
                    Where {$_.Passed -notlike $True}

                "FAILED TESTS SUMMARY:`n"
                $FailedItems | ForEach-Object {
                    $Item = $_
                    [pscustomobject]@{
                        Describe = $Item.Describe
                        Context = $Item.Context
                        Name = "It $($Item.Name)"
                        Result = $Item.Result
                    }
                } |
                    Sort Describe, Context, Name, Result |
                    Format-List

                throw "$FailedCount tests failed."
            }
    }

# Deploy!
    if($Deploy)
    {
        if($ENV:APPVEYOR_REPO_COMMIT_MESSAGE -notmatch '\[ReleaseMe\]')
        {
            Write-Verbose 'Skipping deployment, include [ReleaseMe] in your commit message to deploy.'
        }
        elseif($env:APPVEYOR_REPO_BRANCH -notlike 'master')
        {
            Write-Verbose 'Skipping deployment, not master!'
        }
        else
        {

            $PublishParams = @{
                Path = Join-Path $ENV:APPVEYOR_BUILD_FOLDER $ENV:ModuleName
                NuGetApiKey = $ENV:NugetApiKey
            }
            if($ENV:ReleaseNotes) { $PublishParams.ReleaseNotes = $ENV:ReleaseNotes }
            if($ENV:LicenseUri) { $PublishParams.LicenseUri = $ENV:LicenseUri }
            if($ENV:ProjectUri) { $PublishParams.ProjectUri = $ENV:ProjectUri }
            if($ENV:Tags)
            {
                # split it up, remove whitespace
                $PublishParams.Tags = $ENV:Tags -split ',' | where { $_ } | foreach {$_.trim()}
            }
        
            #Publish!
            Publish-Module @PublishParams
        }
    }