function PrepNonPipelineEnv {
    Write-Output "Setting env vars"
    $env:BUILDVER = "0.0.1"
    Write-Output "BUILDVER = $env:BUILDVER"
    $buildDir = Split-Path -Parent $MyInvocation.ScriptName
    Write-Output "buildDir = $buildDir"
    $env:SYSTEM_DEFAULTWORKINGDIRECTORY = Resolve-Path $buildDir\..\
    Write-Output $env:SYSTEM_DEFAULTWORKINGDIRECTORY
    $env:manifestPath = Join-Path -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY -ChildPath "src\$moduleName.psd1"
    Write-Output "Manifest path = $env:manifestPath"
    $stagingDirName = "drop"
    $env:BUILD_ARTIFACTSTAGINGDIRECTORY = "$env:SYSTEM_DEFAULTWORKINGDIRECTORY\$stagingDirName"
    Write-Output "Copying manifest to output dir"
    if ((Test-Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY) -eq $false) {
        New-Item -ItemType Directory -Name $stagingDirName -Path $env:SYSTEM_DEFAULTWORKINGDIRECTORY | Out-Null
    }
    Copy-Item $env:manifestPath "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\$moduleName.psd1" -Force
    $env:manifestPath = Resolve-Path "$env:BUILD_ARTIFACTSTAGINGDIRECTORY\$moduleName.psd1"
    Write-Output "File copied"
}

$moduleName = 'PreLabminPowerShell'

## Set local vars if running on non-pipeline agent
if ($null -eq $env:AGENT_ID) {
    PrepNonPipelineEnv
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
$manifestContent | Set-Content -Path $env:manifestPath

## Create the actual module file
Write-Output "Creating $moduleName.psm1"
New-Item -Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY -Name "$moduleName.psm1" -ItemType File -Force
## Add function content to the module
foreach ($function in (Get-ChildItem $functionsFolderPath | Select-Object -ExpandProperty FullName)) {
    $content = Get-Content $function
    $content | Set-Content -Path (Join-Path -Path $env:BUILD_ARTIFACTSTAGINGDIRECTORY -ChildPath "$moduleName.psm1")
}