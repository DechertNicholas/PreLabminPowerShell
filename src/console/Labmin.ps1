# Set window properties
# Install needed modules
# Load labmin module
# Set prompt

$shouldCreateShortcut = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Requiem Labs\Labmin\FirstRun\' `
    -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ShouldCreateShortcut
if ($null -eq $shouldCreateShortcut) {
    # Reg value doesn't exist; create, create shortcut, then exit
    Write-Output "Unable to get reg key value, creating the reg key"
    if ((Test-Path "HKCU:\SOFTWARE\Requiem Labs") -eq $false) {
        New-Item -Path "HKCU:\SOFTWARE" -Name "Requiem Labs" | Out-Null
    }
    if ((Test-Path "HKCU:\SOFTWARE\Requiem Labs\Labmin") -eq $false) {
        New-Item -Path "HKCU:\SOFTWARE\Requiem Labs" -Name "Labmin" | Out-Null
    }
    if ((Test-Path "HKCU:\SOFTWARE\Requiem Labs\Labmin\FirstRun") -eq $false) {
        New-Item -Path "HKCU:\SOFTWARE\Requiem Labs\Labmin" -Name "FirstRun" | Out-Null
    }
    Write-Output "Setting reg key value"
    New-ItemProperty -Path "HKCU:\SOFTWARE\Requiem Labs\Labmin\FirstRun" -Name ShouldCreateShortcut -Value 0 | Out-Null
    Write-Output "Creating Labmin Shortcut"
    $ShortcutLocation = "$(Get-Location)\Labmin Console.lnk"
    if (Test-Path $ShortcutLocation -PathType Leaf) {
        Remove-Item -Path $ShortcutLocation
    }

    $SourceFileLocation = "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe"
    $LabminLocation = "$(Get-Location)\Labmin.ps1"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut($ShortcutLocation)
    $Shortcut.TargetPath = $SourceFileLocation
    $Shortcut.Arguments = "-NoExit -Command `"&`'$LabminLocation`'`"" # powershell.exe -NoExit -Command "&'\path\to\Labmin.ps1'"
    # Set the icon location $Shortcut.IconLocation = 
    $Shortcut.Save()
    Write-Output "Shortcut created. Please launch Labmin with the shortcut!"
    return
}

# Some modules needed for operation exist in PowerShell Gallery
$neededModules = @(
    "PSWindowsUpdate"
)

$UserErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = "SilentlyContinue"
$HostWindowSize = (Get-Host).UI.RawUI # Get current HOST window data
$WindowSize = $HostWindowSize.WindowSize # Grab WindowSize specifically
$BufferSize = $HostWindowSize.BufferSize # Same with buffer
$WindowSize.Height = [math]::floor($HostWindowSize.MaxPhysicalWindowSize.Height * .60)
$BufferSize.Height = 9999
$WindowSize.Width = [math]::floor($HostWindowSize.MaxPhysicalWindowSize.Width * .60)
$BufferSize.Width = $WindowSize.Width
$HostWindowSize.BufferSize = $BufferSize
$HostWindowSize.WindowSize = $WindowSize
$ErrorActionPreference = $UserErrorActionPreference

Write-Output "Loading required modules..."

foreach ($moduleName in $neededModules) {
    Write-Output "[$moduleName] Searching for installed versions..."
    $foundModules = Get-Module -Name $moduleName -ListAvailable
    if ($null -eq $foundModules) {
        #Write-Output
    }
}

function global:prompt
{
    "(Labmin [$(hostname)])> "
}