function PrepNonPipelineEnv {
    Write-Output "Setting env vars"
    $env:GITVERSION_SEMVER = "0.0.1" # For local build only
    $env:GITVERSION_BUILDMETADATAPADDED = "0011"
    Write-Output "BUILDVER = $env:BUILDVER"
    $buildDir = Split-Path -Parent $MyInvocation.ScriptName
    Write-Output "buildDir = $buildDir"
    $env:SYSTEM_DEFAULTWORKINGDIRECTORY = Resolve-Path $buildDir\..\
    Write-Output $env:SYSTEM_DEFAULTWORKINGDIRECTORY
    SetManifestPath
    Write-Output "Manifest path = $env:manifestPath"
    $stagingDirName = "drop"
    $env:BUILD_ARTIFACTSTAGINGDIRECTORY = "$env:SYSTEM_DEFAULTWORKINGDIRECTORY\$stagingDirName"
    Write-Output "Creating artifact directory"
    if ((Test-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY) -eq $false) {
        New-Item -ItemType Directory -Name $stagingDirName -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY | Out-Null
    }
    CopyManifestToArtifactDir
}

function SetManifestPath {
    $env:manifestPath = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath "src\$moduleName.psd1"
}

function CopyManifestToArtifactDir {
    Write-Output "Copying manifest to output dir"
    Copy-Item $env:manifestPath "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\$moduleName.psd1" -Force
    $env:manifestPath = Resolve-Path "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\$moduleName.psd1"
    Write-Output "File copied"
}

$moduleName = 'PreLabminPowerShell'

## Set local vars if running on non-pipeline agent
if ($null -eq $env:AGENT_ID) {
    PrepNonPipelineEnv
} else {
    SetManifestPath
    CopyManifestToArtifactDir
    # FOR TESTING! Remove once GitVer is installed and configured
    $env:BUILDVER = "0.0.1"
    # Finish testing area
}

$buildVersion = $env:BUILDVER

## Update build version in manifest
Write-Output "Updating module version"
Update-ModuleManifest -Path $env:manifestPath -ModuleVersion $buildVersion

## Find all of the public functions
Write-Output "Gathering function names for manifest"
$functionsFolderPath = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath 'src\functions'
if ((Test-Path -Path $functionsFolderPath) -and ($publicFunctionNames = Get-ChildItem `
    -Path $functionsFolderPath -Filter '*.ps1' | Select-Object -ExpandProperty BaseName)) {
    $funcStrings = "'$($publicFunctionNames -join "',`n`t'")'"
} else {
    $funcStrings = $null
}
## Add all public functions to FunctionsToExport attribute
Write-Output "Applying function export names"
$manifestContent = Get-Content -Path $env:manifestPath
$manifestContent = $manifestContent -replace "'<FunctionsToExport>'", "@(`n`t$funcStrings`n`t)"
$manifestContent = $manifestContent -replace "'<Prerelease>'", "`'+$env:GITVERSION_BUILDMETADATAPADDED`'"
$manifestContent | Set-Content -Path $env:manifestPath

## Create the actual module file
Write-Output "Creating $moduleName.psm1"
New-Item -Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY -Name "$moduleName.psm1" -ItemType File -Force | Out-Null
Write-Output "File created"
## Add function content to the module
Write-Output "Adding function content to the module"
foreach ($function in (Get-ChildItem $functionsFolderPath | Select-Object -ExpandProperty FullName)) {
    $content = Get-Content $function
    $content | Add-Content -Path (Join-Path -Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY `
        -ChildPath "$moduleName.psm1")
    Write-Output "Function $function added"
}
Write-Output "Build finished successfully!"