function Get-tssDatabaseAssembly {
    [CmdletBinding()]
    param (
        [parameter(Mandatory = $true)]
        [object] $Database,

        [parameter(Mandatory = $true, ValueFromPipeline = $True)]
        [string[]] $AssemblyNames
    )

    BEGIN {
        $DatabaseAssemblies = New-Object -TypeName System.Collections.ArrayList
    }
    
    PROCESS {
        foreach ($AssemblyName in $AssemblyNames){
            foreach ($assembly in $Database.assemblies){
                if ($assembly.name -eq $AssemblyName){
                    $DatabaseAssemblies.Add($assembly) | Out-Null
                }
            }
        }
    }  
    
    END {
        Write-Output $DatabaseAssemblies
    }

}