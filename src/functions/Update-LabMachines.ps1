function Update-LabMachines {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $PoolName,

        [Parameter(Mandatory = $false)]
        [String[]]
        $Machines,

        [Parameter(Mandatory = $false)]
        [Switch]
        $PreserveState,

        [Parameter(Mandatory = $false)]
        [Switch]
        $UpdateOfflineMachines
    )

    <#
        .SYNOPSIS
        Install Windows Updates on a Lab Pool.
    
        .DESCRIPTION
        Install Windows Updates on a Lab Pool or specific machines within the pool. Can startup offline machines
        to update them, then shut them back down if desired. Will MM/Offline VUT guests if present.
    
        .PARAMETER PoolName
        The FQDN of the pool to update.
        
        .PARAMETER Machines
        An array of machine names to update within the pool (will update only those machines, not the whole pool).
    
        .EXAMPLE
        A sample command that uses the function or script, optionally followed by sample output and a description.
        Repeat this keyword for each example.
    #>

    <#
        todo:
        get machines in the pool (for when machines is not specified)
        validate input
        startup offline machine
        if VUT, put guests into MM/Offline
        query updates
        install updates
        reboot machine
        repeat update process until no updates are available
        power off machine
        begin next machine
        log to some place
    #>
}


