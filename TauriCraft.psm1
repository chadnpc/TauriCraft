#!/usr/bin/env pwsh
using namespace System.Collections.Generic
using namespace System.Management.Automation

#Requires -Modules cliHelper.logger, PsModuleBase

#region    Enums and Classes

# Target OS enum for GitHub Actions
enum TargetOS {
  Windows = 0
  MacOS = 1
  Linux = 2
}

class TargetOSConfig {
  [string] $Title
  [string] $Value
  [bool] $Selected

  TargetOSConfig([string]$title, [string]$value, [bool]$selected = $true) {
    $this.Title = $title
    $this.Value = $value
    $this.Selected = $selected
  }
}

class ProjectConfig {
  [string] $ProjectName
  [string] $PackageName
  [string[]] $ReleaseOS
  [bool] $Overwrite
  [string] $TargetDirectory
  [string] $PackageManager

  ProjectConfig() {
    $this.ReleaseOS = @()
    $this.Overwrite = $false
    $this.PackageManager = "npm"
  }
}

# Main class
class TauriCraft : PsModuleBase {
  static [object] $Logger = $null

  static [TargetOSConfig[]] $TargetOperatingSystems = @(
    [TargetOSConfig]::new("Windows (x64)", "windows-latest", $true),
    [TargetOSConfig]::new("macOS (x64)", "macos-latest", $true),
    [TargetOSConfig]::new("Linux (x64)", "ubuntu-latest", $true)
  )

  static [hashtable] $RenameFiles = @{
    "_gitignore" = ".gitignore"
  }

  static [string] $DefaultTargetDir = "tauri-nextjs-app"

  # Initialize logger
  static [void] InitializeLogger() {
    if ($null -eq [TauriCraft]::Logger) {
      [TauriCraft]::Logger = New-Logger -Level 1
    }
  }

  # Static method to get available OS targets
  static [string[]] GetAllOSTargets() {
    [TauriCraft]::InitializeLogger()
    [TauriCraft]::Logger.LogDebugLine("Getting available OS targets")
    return [TauriCraft]::TargetOperatingSystems | ForEach-Object { $_.Value }
  }

  # Main scaffolding method
  static [void] CreateProject([ProjectConfig] $config) {
    [TauriCraft]::CreateProject($config, $PSScriptRoot)
  }

  # Main scaffolding method with module root
  static [void] CreateProject([ProjectConfig] $config, [string] $moduleRoot) {
    [TauriCraft]::InitializeLogger()
    [TauriCraft]::Logger.LogInfoLine("Starting TauriCraft Next.js project creation")
    [TauriCraft]::Logger.LogInfoLine("Project: $($config.ProjectName)")

    try {
      [TauriCraft]::ValidateConfig($config)
      [TauriCraft]::SetupProjectDirectory($config)
      [TauriCraft]::CopyTemplateFiles($config, $moduleRoot)
      [TauriCraft]::ProcessConfigurationFiles($config, $moduleRoot)
      [TauriCraft]::ShowCompletionInstructions($config)

      [TauriCraft]::Logger.LogInfoLine("Project creation completed successfully")
    } catch {
      [TauriCraft]::Logger | Write-LogEntry -Level Error -Message "Project creation failed" -Exception $_.Exception
      throw
    }
  }

  # Validation method
  static [void] ValidateConfig([ProjectConfig] $config) {
    [TauriCraft]::Logger.LogDebugLine("Validating project configuration")

    if ([string]::IsNullOrWhiteSpace($config.ProjectName)) {
      [TauriCraft]::Logger.LogErrorLine("Project name validation failed: empty or null")
      throw "Project name cannot be empty"
    }

    if ([string]::IsNullOrWhiteSpace($config.PackageName)) {
      [TauriCraft]::Logger.LogErrorLine("Package name validation failed: empty or null")
      throw "Package name cannot be empty"
    }

    [TauriCraft]::Logger.LogInfoLine("Configuration validation passed")
  }

  # Directory setup method
  static [void] SetupProjectDirectory([ProjectConfig] $config) {
    $projectRoot = [IO.Path]::Combine((Get-Location) , $config.TargetDirectory)
    [TauriCraft]::Logger.LogInfoLine("Setting up project directory: $projectRoot")

    if ([IO.Directory]::Exists($projectRoot)) {
      [TauriCraft]::Logger.LogDebugLine("Target directory already exists")
      if ($config.Overwrite) {
        [TauriCraft]::Logger.LogWarnLine("Overwriting existing directory contents")
        [TauriCraft]::EmptyDirectory($projectRoot)
      } elseif (![TauriCraft]::IsDirectoryEmpty($projectRoot)) {
        [TauriCraft]::Logger.LogErrorLine("Target directory is not empty and overwrite not specified")
        throw "Target directory '$projectRoot' is not empty. Use -Force to overwrite."
      }
    } else {
      [TauriCraft]::Logger.LogDebugLine("Creating new project directory")
      New-Item -Path $projectRoot -ItemType Directory -Force | Out-Null
    }

    $config.TargetDirectory = $projectRoot
    [TauriCraft]::Logger.LogInfoLine("Project directory setup complete.")
  }

  # Template extraction method
  static [void] CopyTemplateFiles([ProjectConfig] $config, [string] $moduleRoot) {
    $templateZipPath = [IO.Path]::Combine($moduleRoot, "Private", "nextjs-template.zip")
    [TauriCraft]::Logger.LogDebugLine("Template zip path: $templateZipPath")

    if (![IO.File]::Exists($templateZipPath)) {
      [TauriCraft]::Logger.LogErrorLine("Template zip file not found: $templateZipPath")
      throw "Template zip file not found: $templateZipPath"
    }
    [TauriCraft]::Logger.LogInfoLine("Extracting Next.js template to $($config.TargetDirectory)")

    try {
      # Extract the template zip to the target directory
      Expand-Archive -Path $templateZipPath -DestinationPath $config.TargetDirectory -Force -Verbose:$false
      [TauriCraft]::Logger.LogInfoLine("Template extraction completed successfully")

      # Handle file renaming if needed (e.g., _gitignore -> .gitignore)
      [TauriCraft]::ProcessFileRenames($config)
    } catch {
      [TauriCraft]::Logger.LogErrorLine("Failed to extract template: $($_.Exception.Message)")
      throw "Failed to extract template: $($_.Exception.Message)"
    }
  }

  # Process file renames after extraction
  static [void] ProcessFileRenames([ProjectConfig] $config) {
    [TauriCraft]::Logger.LogDebugLine("Processing file renames")

    foreach ($oldName in [TauriCraft]::RenameFiles.Keys) {
      $newName = [TauriCraft]::RenameFiles[$oldName]
      $oldPath = Get-ChildItem $config.TargetDirectory -Recurse -File -Name $oldName -ErrorAction SilentlyContinue

      foreach ($file in $oldPath) {
        $fullOldPath = [IO.Path]::Combine($config.TargetDirectory, $file)
        $fullNewPath = [IO.Path]::Combine((Split-Path $fullOldPath -Parent), $newName)

        if ([IO.File]::Exists($fullOldPath)) {
          [TauriCraft]::Logger.LogDebugLine("Renaming: $file -> $newName")
          Move-Item $fullOldPath $fullNewPath -Force
        }
      }
    }
  }

  # Configuration file processing method
  static [void] ProcessConfigurationFiles([ProjectConfig] $config, [string] $moduleRoot) {
    [TauriCraft]::Logger.LogInfoLine("Processing configuration files...")

    # Process package.json (now in target directory)
    [TauriCraft]::ProcessPackageJson($config)

    # Process tauri.conf.json (now in target directory)
    [TauriCraft]::ProcessTauriConfig($config)

    # Process Cargo.toml (now in target directory)
    [TauriCraft]::ProcessCargoToml($config)

    # Process GitHub Actions release.yml (if exists in extracted template)
    [TauriCraft]::ProcessReleaseWorkflow($config)

    [TauriCraft]::Logger.LogInfoLine("Configuration file processing completed")
  }

  # Package.json processing
  static [void] ProcessPackageJson([ProjectConfig] $config) {
    $packageJsonPath = [IO.Path]::Combine($config.TargetDirectory, "package.json")
    [TauriCraft]::Logger.LogDebugLine("Processing package.json at: $packageJsonPath")

    if ([IO.File]::Exists($packageJsonPath)) {
      $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
      $packageJson.name = $config.PackageName

      $packageJson | ConvertTo-Json -Depth 10 | Set-Content $packageJsonPath -Encoding UTF8
      [TauriCraft]::Logger.LogInfoLine("Updated package.json with name: $($config.PackageName)")
    } else {
      [TauriCraft]::Logger.LogWarnLine("package.json not found in extracted template")
    }
  }

  # Tauri configuration processing
  static [void] ProcessTauriConfig([ProjectConfig] $config) {
    $tauriConfigPath = [IO.Path]::Combine($config.TargetDirectory, "src-tauri", "tauri.conf.json")
    [TauriCraft]::Logger.LogDebugLine("Processing tauri.conf.json at: $tauriConfigPath")

    if ([IO.File]::Exists($tauriConfigPath)) {
      $tauriConfig = Get-Content $tauriConfigPath -Raw | ConvertFrom-Json

      # Update the product name and window title based on the actual structure
      if ($tauriConfig.productName) {
        $tauriConfig.productName = $config.PackageName
        [TauriCraft]::Logger.LogDebugLine("Updated productName to: $($config.PackageName)")
      }

      if ($tauriConfig.app -and $tauriConfig.app.windows -and $tauriConfig.app.windows.Count -gt 0) {
        $tauriConfig.app.windows[0].title = $config.PackageName
        [TauriCraft]::Logger.LogDebugLine("Updated window title to: $($config.PackageName)")
      }

      $tauriConfig | ConvertTo-Json -Depth 10 | Set-Content $tauriConfigPath -Encoding UTF8
      [TauriCraft]::Logger.LogInfoLine("Updated tauri.conf.json configuration")
    } else {
      [TauriCraft]::Logger.LogWarnLine("tauri.conf.json not found in extracted template")
    }
  }

  # Cargo.toml processing
  static [void] ProcessCargoToml([ProjectConfig] $config) {
    $cargoPath = [IO.Path]::Combine($config.TargetDirectory, "src-tauri", "Cargo.toml")
    [TauriCraft]::Logger.LogDebugLine("Processing Cargo.toml at: $cargoPath")

    if ([IO.File]::Exists($cargoPath)) {
      $cargoContent = Get-Content $cargoPath -Raw
      $updatedContent = $cargoContent -replace 'name\s*=\s*"[^"]*"', "name = `"$($config.PackageName)`""

      Set-Content $cargoPath $updatedContent -Encoding UTF8
      [TauriCraft]::Logger.LogInfoLine("Set app name to $($config.PackageName)")
    } else {
      [TauriCraft]::Logger.LogWarnLine("Cargo.toml not found in extracted template")
    }
  }

  # GitHub Actions release workflow processing
  static [void] ProcessReleaseWorkflow([ProjectConfig] $config) {
    $releaseYmlPath = [IO.Path]::Combine($config.TargetDirectory, ".github", "workflows", "release.yml")
    [TauriCraft]::Logger.LogDebugLine("Processing release.yml at: $releaseYmlPath")

    if ([IO.File]::Exists($releaseYmlPath)) {
      $releaseContent = Get-Content $releaseYmlPath -Raw
      $allOS = [TauriCraft]::GetAllOSTargets()
      $selectedOS = $config.ReleaseOS -join ", "

      $comment = ""
      if ($config.ReleaseOS.Count -lt $allOS.Count) {
        $excludedOS = $allOS | Where-Object { $_ -notin $config.ReleaseOS }
        $comment = " # $($excludedOS -join ', ')"
      }

      $updatedContent = $releaseContent -replace
      "platform: \[macos-latest, ubuntu-latest, windows-latest\]",
      "platform: [$selectedOS]$comment"

      Set-Content $releaseYmlPath $updatedContent -Encoding UTF8
      [TauriCraft]::Logger.LogInfoLine("Updated GitHub Actions workflow for platforms: $selectedOS")
    } else {
      [TauriCraft]::Logger.LogWarnLine("release.yml not found in extracted template")
    }
  }

  # Completion instructions
  static [void] ShowCompletionInstructions([ProjectConfig] $config) {
    $relativePath = Resolve-Path $config.TargetDirectory -Relative

    Write-Host "`nNext.js Tauri project created successfully! 🎉" -ForegroundColor Green
    Write-Host "Log file saved in $([TauriCraft]::Logger.Logdir)"
    Write-Host "`nTo get started:" -ForegroundColor Yellow

    if ($config.TargetDirectory -ne (Get-Location).Path) {
      if ($relativePath.Contains(" ")) {
        Write-Host "  cd `"$relativePath`"" -ForegroundColor Cyan
      } else {
        Write-Host "  cd $relativePath" -ForegroundColor Cyan
      }
    }

    switch ($config.PackageManager) {
      "yarn" {
        Write-Host "  yarn install" -ForegroundColor Cyan
        Write-Host "  yarn tauri dev" -ForegroundColor Cyan
      }
      "pnpm" {
        Write-Host "  pnpm install" -ForegroundColor Cyan
        Write-Host "  pnpm tauri dev" -ForegroundColor Cyan
      }
      default {
        Write-Host "  $($config.PackageManager) install" -ForegroundColor Cyan
        Write-Host "  $($config.PackageManager) run tauri dev" -ForegroundColor Cyan
      }
    }
    Write-Host ""
  }

  # Utility methods
  static [bool] IsDirectoryEmpty([string] $path) {
    if (![IO.Path]::Exists($path)) {
      return $true
    }

    $items = Get-ChildItem $path -Force
    return $items.Count -eq 0 -or ($items.Count -eq 1 -and $items[0].Name -eq ".git")
  }

  static [void] EmptyDirectory([string] $path) {
    if (![IO.Path]::Exists($path)) {
      return
    }

    Get-ChildItem $path -Force | Where-Object { $_.Name -ne ".git" } | Remove-Item -Recurse -Force
  }

  static [bool] IsValidPackageName([string] $name) {
    return $name -match '^(?:@[a-z\d\-*~][a-z\d\-*._~]*\/)?[a-z\d\-~][a-z\d\-._~]*$'
  }

  static [string] ToValidPackageName([string] $name) {
    return $name.Trim().ToLower() -replace '\s+', '-' -replace '^[._]', '' -replace '[^a-z\d\-~]+', '-'
  }

  static [string] FormatTargetDirectory([string] $targetDir) {
    if ([string]::IsNullOrWhiteSpace($targetDir)) {
      return ""
    }
    return $targetDir.Trim() -replace '/+$', ''
  }

  static [hashtable] DetectPackageManager() {
    $userAgent = $env:npm_config_user_agent
    if ([string]::IsNullOrWhiteSpace($userAgent)) {
      return @{ name = "npm"; version = "" }
    }

    $pkgSpec = $userAgent.Split(" ")[0]
    $pkgSpecArr = $pkgSpec.Split("/")

    return @{
      name    = $pkgSpecArr[0]
      version = if ($pkgSpecArr.Length -gt 1) { $pkgSpecArr[1] } else { "" }
    }
  }
  static [void] ShowTemplateInfo() {
    [TauriCraft]::ShowTemplateInfo($true)
  }
  static [void] ShowTemplateInfo([bool]$full) {
    Write-Host "TauriCraft - Next.js Template" -ForegroundColor Green
    Write-Host "=============================" -ForegroundColor Green
    Write-Host ""

    Write-Host "tech stack: " -NoNewline -ForegroundColor Yellow
    Write-Host "▲ Next.js + 🦀 Tauri-v2 backend" -ForegroundColor Cyan
    Write-Host "    Best for:" -NoNewline -ForegroundColor Gray
    Write-Host "🔥 Blazingly fast, full-stack desktop apps with small bundle size" -ForegroundColor White
    Write-Host ""

    if ($Full) {
      Write-Host "Target OS" -ForegroundColor Green
      Write-Host "=========" -ForegroundColor Green
      Write-Host ""

      $targetOS = [TauriCraft]::TargetOperatingSystems
      foreach ($os in $targetOS) {
        Write-Host "• " -NoNewline -ForegroundColor Yellow
        Write-Host $os.Title -NoNewline -ForegroundColor Cyan
        Write-Host " (" -NoNewline -ForegroundColor Gray
        Write-Host $os.Value -NoNewline -ForegroundColor White
        Write-Host ")" -ForegroundColor Gray
      }
      Write-Host ""
    }

    Write-Host "Usage Examples:" -ForegroundColor Green
    Write-Host "  New-TauriProject" -ForegroundColor Cyan
    Write-Host "  New-TauriProject -Name 'my-app'" -ForegroundColor Cyan
    Write-Host "  New-TauriProject -Interactive" -ForegroundColor Cyan
    Write-Host ""
  }

  # Dispose logger resources
  static [void] DisposeLogger() {
    if ($null -ne [TauriCraft]::Logger) {
      [TauriCraft]::Logger.LogInfoLine("Disposing TauriCraft logger")
      [TauriCraft]::Logger.Dispose()
      [TauriCraft]::Logger = $null
    }
  }
}
#endregion Classes

# Types that will be available to users when they import the module.
$typestoExport = @(
  [TauriCraft],
  [TargetOSConfig],
  [ProjectConfig],
  [TargetOS]
)
$TypeAcceleratorsClass = [PsObject].Assembly.GetType('System.Management.Automation.TypeAccelerators')
foreach ($Type in $typestoExport) {
  if ($Type.FullName -in $TypeAcceleratorsClass::Get.Keys) {
    $Message = @(
      "Unable to register type accelerator '$($Type.FullName)'"
      'Accelerator already exists.'
    ) -join ' - '
    "TypeAcceleratorAlreadyExists $Message" | Write-Debug
  }
}
# Add type accelerators for every exportable type.
foreach ($Type in $typestoExport) {
  $TypeAcceleratorsClass::Add($Type.FullName, $Type)
}
# Remove type accelerators when the module is removed.
$MyInvocation.MyCommand.ScriptBlock.Module.OnRemove = {
  # Dispose logger resources
  [TauriCraft]::DisposeLogger()

  # Remove type accelerators
  foreach ($Type in $typestoExport) {
    $TypeAcceleratorsClass::Remove($Type.FullName)
  }
}.GetNewClosure();

$scripts = @();
$Public = Get-ChildItem "$PSScriptRoot/Public" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
$scripts += Get-ChildItem "$PSScriptRoot/Private" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
$scripts += $Public

foreach ($file in $scripts) {
  try {
    if ([string]::IsNullOrWhiteSpace($file.fullname)) { continue }
    . "$($file.fullname)"
  } catch {
    Write-Warning "Failed to import function $($file.BaseName): $_"
    $host.UI.WriteErrorLine($_)
  }
}

$Param = @{
  Function = $Public.BaseName
  Cmdlet   = '*'
  Alias    = '*'
  Verbose  = $false
}
Export-ModuleMember @Param
