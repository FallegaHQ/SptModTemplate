<#
.SYNOPSIS
  Scaffolds a new SPT mod from this template repository.

.DESCRIPTION
  Interactive wizard by default. Pass -NonInteractive with -Name, -OutputDir, and -TarkovDir for automation.

.EXAMPLE
  .\New-SptMod.ps1

.EXAMPLE
  .\New-SptMod.ps1 -Name MyRaidMod -OutputDir C:\Dev\SPT-MyRaidMod -TarkovDir "D:\Games\Escape from Tarkov" -AuthorPrefix Acme -GuidPrefix com.acme -GitInit -NonInteractive
#>
param(
    [string]$Name,
    [string]$OutputDir,
    [string]$TarkovDir,
    [string]$DisplayName,
    [string]$LogPrefix,
    [string]$AuthorPrefix,
    [string]$GuidPrefix,
    [switch]$GitInit,
    [switch]$NonInteractive
)

$ErrorActionPreference = 'Stop'

$templateRoot = Split-Path $PSScriptRoot -Parent

function Write-Banner
{
    Write-Host ''
    Write-Host '  Softwyx SPT Mod Template' -ForegroundColor Cyan
    Write-Host '  New project wizard' -ForegroundColor DarkCyan
    Write-Host ('  ' + ('-' * 40)) -ForegroundColor DarkGray
    Write-Host ''
}

function Read-Default
{
    param([string]$Prompt, [string]$Default)
    $raw = Read-Host "$Prompt [$Default]"
    if ( [string]::IsNullOrWhiteSpace($raw))
    {
        return $Default
    }
    return $raw.Trim()
}

function Read-YesNo
{
    param([string]$Prompt, [bool]$DefaultYes = $true)
    $hint = if ($DefaultYes)
    {
        'Y/n'
    }
    else
    {
        'y/N'
    }
    while ($true)
    {
        $raw = Read-Host "$Prompt ($hint)"
        if ( [string]::IsNullOrWhiteSpace($raw))
        {
            return $DefaultYes
        }
        switch ( $raw.Trim().ToLowerInvariant())
        {
            { $_ -in 'y', 'yes' } {
                return $true
            }
            { $_ -in 'n', 'no' } {
                return $false
            }
            default {
                Write-Host '  Enter Y or N.' -ForegroundColor Yellow
            }
        }
    }
}

function Test-PascalCaseName
{
    param([string]$Value)
    return $Value -match '^[A-Z][a-zA-Z0-9]*$'
}

function Test-GuidPrefix
{
    param([string]$Value)
    return $Value -match '^[a-z][a-z0-9]*(\.[a-z][a-z0-9]*)*$'
}

function Get-DefaultTarkovDir
{
    $userProps = Join-Path $templateRoot 'Directory.Build.props.user'
    if (Test-Path $userProps)
    {
        $text = [IO.File]::ReadAllText($userProps)
        if ($text -match '<TarkovDir>([^<]+)</TarkovDir>')
        {
            return $Matches[1].Trim()
        }
    }

    $sharedProps = Join-Path $templateRoot 'Directory.Build.props'
    if (Test-Path $sharedProps)
    {
        $text = [IO.File]::ReadAllText($sharedProps)
        if ($text -match '<TarkovDir[^>]*>([^<]+)</TarkovDir>')
        {
            return $Matches[1].Trim()
        }
    }

    return 'D:\Games\Escape from Tarkov'
}

function Test-TarkovInstall
{
    param([string]$Path)
    if ( [string]::IsNullOrWhiteSpace($Path))
    {
        return $false
    }
    $managed = Join-Path $Path 'EscapeFromTarkov_Data\Managed\Assembly-CSharp.dll'
    $bepinex = Join-Path $Path 'BepInEx\core\BepInEx.dll'
    return (Test-Path $managed) -and (Test-Path $bepinex)
}

function Read-TarkovDir
{
    param([string]$DefaultPath)
    while ($true)
    {
        $path = Read-Default 'SPT / EFT install path (TarkovDir)' $DefaultPath
        if (Test-TarkovInstall $path)
        {
            return $path
        }

        Write-Host '  Assembly-CSharp.dll or BepInEx.dll not found at that path.' -ForegroundColor Yellow
        if (Read-YesNo 'Use this path anyway?' $false)
        {
            return $path
        }

        $DefaultPath = $path
    }
}

function Show-Summary
{
    param(
        [string]$ModName,
        [string]$ModAuthorPrefix,
        [string]$ModGuidPrefix,
        [string]$ModDisplayName,
        [string]$ModLogPrefix,
        [string]$ModOutputDir,
        [string]$ModTarkovDir,
        [bool]$ModGitInit,
        [string]$ModAssemblyName,
        [string]$ModGuid,
        [string]$ModSigningSubject
    )

    Write-Host ''
    Write-Host '  Summary' -ForegroundColor Cyan
    Write-Host ('  ' + ('-' * 40)) -ForegroundColor DarkGray
    Write-Host "  Mod name       : $ModName"
    Write-Host "  Author prefix  : $ModAuthorPrefix"
    Write-Host "  GUID prefix    : $ModGuidPrefix"
    Write-Host "  Display name   : $ModDisplayName"
    Write-Host "  Log prefix     : [$ModLogPrefix]"
    Write-Host "  Assembly       : $ModAssemblyName"
    Write-Host "  Plugin GUID    : $ModGuid"
    Write-Host "  Signing subject: $ModSigningSubject"
    Write-Host "  Output folder  : $ModOutputDir"
    Write-Host "  TarkovDir      : $ModTarkovDir"
    Write-Host "  Git init       : $( if ($ModGitInit)
    {
        'Yes'
    }
    else
    {
        'No'
    } )"
    Write-Host ''
}

function Copy-TemplateTree
{
    param([string]$Source, [string]$Destination)

    New-Item -ItemType Directory -Path $Destination -Force | Out-Null

    $excludeDirs = @('bin', 'obj', 'Package', '.git', '.idea', '_temp')
    $excludeFiles = @('Directory.Build.props.user', 'New-SptMod.ps1')

    Get-ChildItem -Path $Source -Force | ForEach-Object {
        if ($_.PSIsContainer)
        {
            if ($excludeDirs -contains $_.Name)
            {
                return
            }
            Copy-TemplateTree -Source $_.FullName -Destination (Join-Path $Destination $_.Name)
        }
        else
        {
            if ($excludeFiles -contains $_.Name)
            {
                return
            }
            Copy-Item -LiteralPath $_.FullName -Destination (Join-Path $Destination $_.Name) -Force
        }
    }
}

function Invoke-Scaffold
{
    param(
        [string]$ModName,
        [string]$ModOutputDir,
        [string]$ModTarkovDir,
        [string]$ModDisplayName,
        [string]$ModLogPrefix,
        [string]$ModAuthorPrefix,
        [string]$ModGuidPrefix,
        [bool]$ModGitInit
    )

    if (-not (Test-PascalCaseName $ModName))
    {
        throw 'Mod name must be PascalCase (e.g. MyRaidMod).'
    }

    if (-not (Test-PascalCaseName $ModAuthorPrefix))
    {
        throw 'Author prefix must be PascalCase (e.g. Softwyx, Acme).'
    }

    if (-not (Test-GuidPrefix $ModGuidPrefix))
    {
        throw 'GUID prefix must be lowercase dotted segments (e.g. com.softwyx, com.acme).'
    }

    if ( [string]::IsNullOrWhiteSpace($ModTarkovDir))
    {
        throw 'TarkovDir is required.'
    }

    if (Test-Path $ModOutputDir)
    {
        throw "Output directory already exists: $ModOutputDir"
    }

    $assemblyName = "$ModAuthorPrefix.$ModName"
    $rootNamespace = $assemblyName
    $pluginGuid = "$ModGuidPrefix.$($ModName.ToLowerInvariant() )"

    if ( [string]::IsNullOrWhiteSpace($ModDisplayName))
    {
        $ModDisplayName = ($ModName -creplace '([A-Z])', ' $1').Trim()
    }

    if ( [string]::IsNullOrWhiteSpace($ModLogPrefix))
    {
        $ModLogPrefix = if ($ModName.Length -ge 3)
        {
            $ModName.Substring(0, 3).ToUpperInvariant()
        }
        else
        {
            $ModName.ToUpperInvariant()
        }
    }

    $replacementPairs = @(
        @('SptModTemplatePlugin', "${ModName}Plugin"),
        @('Softwyx.SptModTemplate', $rootNamespace),
        @('Softwyx-SptModTemplate', "$ModAuthorPrefix-$ModName"),
        @('com.softwyx.sptmodtemplate', $pluginGuid),
        @('sptmodtemplate',$ModName.ToLowerInvariant()),
        @('SptModTemplate', $ModName),
        @('Spt Mod Template', $ModDisplayName),
        @('SMT', $ModLogPrefix),
        @('CN=Softwyx.SptModTemplate', "CN=$assemblyName"),
        @('certs\Softwyx.SptModTemplate.pfx', "certs\$assemblyName.pfx")
    )

    Write-Host ''
    Write-Host 'Creating project...' -ForegroundColor Green
    Copy-TemplateTree -Source $templateRoot -Destination $ModOutputDir

    $textExtensions = @('.cs', '.csproj', '.props', '.targets', '.md', '.sln', '.ps1', '.mdc', '.editorconfig', '.gitignore', '.gitattributes', '.yaml', '.yml', '.json', '.example')
    $utf8NoBom = New-Object System.Text.UTF8Encoding $false

    Get-ChildItem -Path $ModOutputDir -Recurse -File | ForEach-Object {
        if ($textExtensions -notcontains $_.Extension)
        {
            return
        }

        $content = [IO.File]::ReadAllText($_.FullName)
        foreach ($pair in $replacementPairs)
        {
            $content = $content.Replace($pair[0], $pair[1])
        }
        [IO.File]::WriteAllText($_.FullName, $content, $utf8NoBom)
    }

    $renameMap = @{
        'Softwyx.SptModTemplate.csproj' = "$assemblyName.csproj"
        'Softwyx.SptModTemplate.sln' = "$ModAuthorPrefix-$ModName.sln"
        'SptModTemplatePlugin.cs' = "${ModName}Plugin.cs"
    }

    Get-ChildItem -Path $ModOutputDir -Recurse -File | ForEach-Object {
        foreach ($entry in $renameMap.GetEnumerator())
        {
            if ($_.Name -eq $entry.Key)
            {
                Rename-Item -LiteralPath $_.FullName -NewName $entry.Value
            }
        }
    }

    $userPropsPath = Join-Path $ModOutputDir 'Directory.Build.props.user'
    @"
<Project>
  <PropertyGroup>
    <TarkovDir>$ModTarkovDir</TarkovDir>
    <DeployToPlugins>true</DeployToPlugins>
  </PropertyGroup>

  <!-- Code signing — on by default for Release/Package (see Directory.Build.props) -->
  <PropertyGroup>
    <!-- <SignAssembly>false</SignAssembly> -->
    <!-- <SigningPfxPath>certs\$assemblyName.pfx</SigningPfxPath> -->
    <!-- <SigningPfxPassword></SigningPfxPassword> -->
    <!-- <SigningPfxExportPath>certs\$assemblyName.pfx</SigningPfxExportPath> -->
  </PropertyGroup>
</Project>
"@ | Set-Content -Path $userPropsPath -Encoding UTF8

    $attributionSrc = Join-Path $templateRoot 'TEMPLATE-ATTRIBUTION.md'
    if (Test-Path $attributionSrc)
    {
        Copy-Item -LiteralPath $attributionSrc -Destination (Join-Path $ModOutputDir 'TEMPLATE-ATTRIBUTION.md') -Force
    }

    $licenseSrc = Join-Path $templateRoot 'LICENSE'
    if (Test-Path $licenseSrc)
    {
        Copy-Item -LiteralPath $licenseSrc -Destination (Join-Path $ModOutputDir 'LICENSE') -Force
    }

    $readme = @"
# $ModDisplayName

SPT 4.x BepInEx mod.

> This project was created using the **Softwyx SPT Mod Template** (by [softwyx.com](https://softwyx.com)).

## Build

1. ``TarkovDir`` is in ``Directory.Build.props.user`` — adjust if your install moves.
2. ``dotnet build -c Debug`` — deploys to ``BepInEx/plugins/$assemblyName/``
3. ``dotnet build -c Package`` — release ZIP under ``Package/`` (Authenticode-signed by default)

Validate install: ``.\scripts\Validate-Install.ps1``

See the template ``README.md`` (or upstream docs) for localization, config UI drawers, and signing options.
"@

    Set-Content -Path (Join-Path $ModOutputDir 'README.md') -Value $readme -Encoding UTF8

    if ($ModGitInit)
    {
        Push-Location $ModOutputDir
        try
        {
            git init | Out-Null
            git add -A | Out-Null
            git commit -m "Initial commit from Softwyx SPT Mod Template." | Out-Null
            Write-Host 'Git repository initialized.' -ForegroundColor Green
        }
        finally
        {
            Pop-Location
        }
    }

    Write-Host ''
    Write-Host "Done: $ModOutputDir" -ForegroundColor Green
}

function Invoke-ValidateInstall
{
    param([string]$ModOutputDir, [string]$ModTarkovDir)

    $validateScript = Join-Path $templateRoot 'scripts\Validate-Install.ps1'
    if (-not (Test-Path $validateScript))
    {
        Write-Host 'Validate-Install.ps1 not found; skipping install check.' -ForegroundColor Yellow
        return
    }

    Write-Host ''
    Write-Host 'Running install validation...' -ForegroundColor Cyan
    & $validateScript -ProjectDir $ModOutputDir -TarkovDir $ModTarkovDir
    if ($LASTEXITCODE -ne 0)
    {
        Write-Host 'Install validation failed. Fix TarkovDir before building.' -ForegroundColor Yellow
    }
}

# --- Interactive wizard ---

if (-not $NonInteractive)
{
    Write-Banner

    while (-not (Test-PascalCaseName $Name))
    {
        $Name = Read-Default 'Mod name (PascalCase)' 'MySptMod'
        if (-not (Test-PascalCaseName $Name))
        {
            Write-Host '  Use PascalCase letters and digits only, starting with a capital (e.g. MyRaidMod).' -ForegroundColor Yellow
        }
    }

    while (-not (Test-PascalCaseName $AuthorPrefix))
    {
        $AuthorPrefix = Read-Default 'Author prefix (namespace segment)' 'Softwyx'
        if (-not (Test-PascalCaseName $AuthorPrefix))
        {
            Write-Host '  Use PascalCase (e.g. Softwyx, Acme).' -ForegroundColor Yellow
        }
    }

    while (-not (Test-GuidPrefix $GuidPrefix))
    {
        $GuidPrefix = Read-Default 'Plugin GUID prefix' 'com.softwyx'
        if (-not (Test-GuidPrefix $GuidPrefix))
        {
            Write-Host '  Use lowercase dotted segments (e.g. com.softwyx, com.acme).' -ForegroundColor Yellow
        }
    }

    $defaultDisplay = ($Name -creplace '([A-Z])', ' $1').Trim()
    $DisplayName = Read-Default 'Display name (in-game / BepInEx list)' $defaultDisplay

    $defaultPrefix = if ($Name.Length -ge 3)
    {
        $Name.Substring(0, 3).ToUpperInvariant()
    }
    else
    {
        $Name.ToUpperInvariant()
    }
    $LogPrefix = Read-Default 'Log prefix (2-6 chars)' $defaultPrefix

    $defaultOutput = Join-Path ([Environment]::GetFolderPath('Desktop')) "SPT-$Name"
    while ($true)
    {
        $OutputDir = Read-Default 'Output folder' $defaultOutput
        if (-not (Test-Path $OutputDir))
        {
            break
        }
        Write-Host "  Folder already exists: $OutputDir" -ForegroundColor Yellow
        $defaultOutput = $OutputDir
    }

    $TarkovDir = Read-TarkovDir -DefaultPath (Get-DefaultTarkovDir)

    $GitInit = Read-YesNo 'Initialize a git repository?' $true

    $assemblyPreview = "$AuthorPrefix.$Name"
    $guidPreview = "$GuidPrefix.$($Name.ToLowerInvariant() )"
    Show-Summary -ModName $Name -ModAuthorPrefix $AuthorPrefix -ModGuidPrefix $GuidPrefix `
        -ModDisplayName $DisplayName -ModLogPrefix $LogPrefix `
        -ModOutputDir $OutputDir -ModTarkovDir $TarkovDir -ModGitInit $GitInit `
        -ModAssemblyName $assemblyPreview -ModGuid $guidPreview `
        -ModSigningSubject "CN=$assemblyPreview"

    if (-not (Read-YesNo 'Create project?' $true))
    {
        Write-Host 'Cancelled.' -ForegroundColor Yellow
        exit 0
    }
}
else
{
    if ([string]::IsNullOrWhiteSpace($Name) -or [string]::IsNullOrWhiteSpace($OutputDir))
    {
        throw 'NonInteractive mode requires -Name and -OutputDir.'
    }

    if ( [string]::IsNullOrWhiteSpace($AuthorPrefix))
    {
        $AuthorPrefix = 'Softwyx'
    }
    if ( [string]::IsNullOrWhiteSpace($GuidPrefix))
    {
        $GuidPrefix = 'com.softwyx'
    }

    if ( [string]::IsNullOrWhiteSpace($TarkovDir))
    {
        $TarkovDir = Get-DefaultTarkovDir
        if ( [string]::IsNullOrWhiteSpace($TarkovDir))
        {
            throw 'NonInteractive mode requires -TarkovDir when no default is configured.'
        }
    }
}

Invoke-Scaffold -ModName $Name -ModOutputDir $OutputDir -ModTarkovDir $TarkovDir `
    -ModDisplayName $DisplayName -ModLogPrefix $LogPrefix `
    -ModAuthorPrefix $AuthorPrefix -ModGuidPrefix $GuidPrefix -ModGitInit:$GitInit

Invoke-ValidateInstall -ModOutputDir $OutputDir -ModTarkovDir $TarkovDir

Write-Host 'Next: dotnet build -c Debug' -ForegroundColor DarkGray

if (-not $NonInteractive)
{
    if (Read-YesNo 'Open output folder in Explorer?' $true)
    {
        Start-Process explorer.exe $OutputDir
    }
}
