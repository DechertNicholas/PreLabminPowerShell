function Get-LabMachine {
    [CmdletBinding()]
    [Alias("glm")]
    param (
        [Parameter(ParameterSetName = "Machine", Position = 0)]
        [String]
        $MachineName,

        [Parameter(ParameterSetName = "Pool")]
        [String]
        $PoolName
    )

    <#
        .SYNOPSIS
        Get Lab Machines by name or by pool.
    
        .DESCRIPTION
        Gets a grouping of Lab Machines by specifying a machine name or a pool name
    
        .PARAMETER
        The description of a parameter. Add a .PARAMETER <Parameter-Name> keyword for each parameter in the function or script syntax.
    
        .EXAMPLE
        A sample command that uses the function or script, optionally followed by sample output and a description. Repeat this keyword for each example.
    
        .INPUTS
        The .NET types of objects that can be piped to the function or script. You can also include a description of the input objects.
    
        .OUTPUTS
        The .NET type of the objects that the cmdlet returns. You can also include a description of the returned objects.
    
        .NOTES
        Additional information about the function or script.
    #>

    Write-Verbose "Getting Datasource location"
    $csvLocation = Get-ItemProperty -Path 'HKLM:\SOFTWARE\Requiem Labs\Labmin\Environment Config\' `
        | Select-Object -ExpandProperty Datasource
    if ($null -eq $csvLocation) {
        $message = "Unable to determine CSV location. Check reg key HKLM:\SOFTWARE\Requiem Labs\Labmin\"`
        + "Environment Config\, Datasource property"
        #LogLabminOperation -Message $message -LogType "Error"
        throw $message
    }
    #LogLabminOperation -Message "Found Datasource at $csvLocation" -LogType "Success"
    
    $csv = Import-Csv $csvLocation
    
    switch ($PSCmdlet.ParameterSetName) {
        'Machine' {
            return $csv | Where-Object -FilterScript {$_.Name -like $MachineName}
        }

        'Pool' {
            return $csv | Where-Object -FilterScript {$_.Pool -like $PoolName}
        }
    }
}