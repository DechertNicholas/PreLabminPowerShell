# Set window properties
# Install needed modules
# Load labmin module
# Set prompt

[CmdletBinding()]
param (
    [Parameter()]
    [Switch]
    $GenerateShortcut
)

$shouldCreateShortcut = Get-ItemProperty -Path 'HKCU:\SOFTWARE\Requiem Labs\Labmin\FirstRun\' `
    -ErrorAction SilentlyContinue | Select-Object -ExpandProperty ShouldCreateShortcut
if ($null -eq $shouldCreateShortcut -or $GenerateShortcut -eq $true) {
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
    New-ItemProperty -Path "HKCU:\SOFTWARE\Requiem Labs\Labmin\FirstRun" -Name ShouldCreateShortcut -Value 0 `
        -ErrorAction SilentlyContinue | Out-Null
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
    $Shortcut.WorkingDirectory = "$(Get-Location)"
    # Set the icon location $Shortcut.IconLocation = 
    $Shortcut.Save()

    # Set the "Run as admin" flag (this is needed for Updates and other things)
    $bytes = [System.IO.File]::ReadAllBytes("$(Get-Location)\Labmin Console.lnk")
    $bytes[0x15] = $bytes[0x15] -bor 0x20 #set byte 21 (0x15) bit 6 (0x20) ON
    [System.IO.File]::WriteAllBytes("$(Get-Location)\Labmin Console.lnk", $bytes)
    Write-Output "Shortcut created. Please launch Labmin with the shortcut!"
    return
}

# Running as admin sets location to system32, need to be in labmin dir to load modules
$absoluteScriptPath = ($MyInvocation.Line -split "&")[1]
$absoluteScriptPath = $absoluteScriptPath -replace "`'", ""
$absoluteScriptPath = $absoluteScriptPath -replace "Labmin.ps1", ""
Set-Location $absoluteScriptPath

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
        Write-Output "[$moduleName] Unable to find any local versions of $moduleName. Prompting for install"
        Install-Module -Name $moduleName
        Import-Module -Name $moduleName -RequiredVersion $latestVersion
    } else {
        $latestVersion = $foundModules[$foundModules.Count - 1].Version
        Write-Output "[$moduleName] Found version $latestVersion. Loading module..."
        Import-Module -Name $moduleName -RequiredVersion $latestVersion
    }
}

Write-Output "Loading Labmin modules..."
$modules = Get-ChildItem ".\modules\*.psd1"
foreach ($module in $modules) {
    $info = Get-Module $module -ListAvailable
    Write-Output "[$($info.Name)] Loading version $($info.Version)..."
    Import-Module $module
}

Write-Output "Ready!"

function global:prompt
{
    "(Labmin [$(hostname)])> "
}