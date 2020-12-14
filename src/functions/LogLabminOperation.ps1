function LogLabminOperation {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        $Message,

        [Parameter()]
        [ValidateSet("Info", "Success", "Error")]
        [String]
        $LogType
    )

    # Currently this only supports logging to the console. Use a transcript to save to a file

    switch ($LogType) {
        'Info' {
            Write-Output "[*] INFO: $Message"
        }

        'Success' {
            Write-Output "[+] SUCCESS: $Message"
        }

        'Error' {
            Write-Output "[-] ERROR: $Message"
        }
    }
}