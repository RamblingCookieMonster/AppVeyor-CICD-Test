@{
    Psake = @{
        Target = 'C:\temp'
        Parameters = @{ Force = $True }
        Import = $True
    }
    PSDeploy = @{
        Target = 'C:\temp'
        Import = $True
    }
    Pester = @{
        Target = 'C:\temp'
        Import = $True
    }
    BuildHelpers = @{
        Target = 'C:\temp'
        Import = $True
    }
}