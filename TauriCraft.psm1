#!/usr/bin/env pwsh
using namespace System.Collections.Generic
using namespace System.Management.Automation

#Requires -Modules cliHelper.logger, PsModuleBase

#region    Enums and Classes
enum FrameworkType {
  Vite = 0
  Next = 1
  SvelteKit = 2
}

# Target OS enum for GitHub Actions
enum TargetOS {
  Windows = 0
  MacOS = 1
  Linux = 2
}
class Framework {
  [string] $Name
  [string] $Display
  [string] $Color

  Framework([string]$name, [string]$display, [string]$color) {
    $this.Name = $name
    $this.Display = $display
    $this.Color = $color
  }
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
  [Framework] $Framework
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
  static [Framework[]] $Frameworks = @(
    [Framework]::new("vite", "⚡Vite + React", "Blue"),
    [Framework]::new("next", "▲ Next.js", "Blue"),
    [Framework]::new("sveltekit", "⚡Vite + SvelteKit", "Blue")
  )

  static [TargetOSConfig[]] $TargetOperatingSystems = @(
    [TargetOSConfig]::new("Windows (x64)", "windows-latest", $true),
    [TargetOSConfig]::new("macOS (x64)", "macos-latest", $true),
    [TargetOSConfig]::new("Linux (x64)", "ubuntu-latest", $true)
  )

  static [hashtable] $RenameFiles = @{
    "_gitignore" = ".gitignore"
  }

  static [string] $DefaultTargetDir = "tauri-ui"

  # Static method to get available templates
  static [string[]] GetTemplates() {
    return [TauriCraft]::Frameworks | ForEach-Object { $_.Name }
  }

  # Static method to get available OS targets
  static [string[]] GetAllOSTargets() {
    return [TauriCraft]::TargetOperatingSystems | ForEach-Object { $_.Value }
  }

  # Main scaffolding method
  static [void] CreateProject([ProjectConfig] $config) {
    [TauriCraft]::CreateProject($config, $PSScriptRoot)
  }

  # Main scaffolding method with module root
  static [void] CreateProject([ProjectConfig] $config, [string] $moduleRoot) {
    [TauriCraft]::ValidateConfig($config)
    [TauriCraft]::SetupProjectDirectory($config)
    [TauriCraft]::CopyTemplateFiles($config, $moduleRoot)
    [TauriCraft]::ProcessConfigurationFiles($config, $moduleRoot)
    [TauriCraft]::ShowCompletionInstructions($config)
  }

  # Validation method
  static [void] ValidateConfig([ProjectConfig] $config) {
    if ([string]::IsNullOrWhiteSpace($config.ProjectName)) {
      throw "Project name cannot be empty"
    }

    if ([string]::IsNullOrWhiteSpace($config.PackageName)) {
      throw "Package name cannot be empty"
    }

    if ($null -eq $config.Framework) {
      throw "Framework must be specified"
    }

    $validTemplates = [TauriCraft]::GetTemplates()
    if ($config.Framework.Name -notin $validTemplates) {
      throw "Invalid framework: $($config.Framework.Name). Valid options: $($validTemplates -join ', ')"
    }
  }

  # Directory setup method
  static [void] SetupProjectDirectory([ProjectConfig] $config) {
    $projectRoot = Join-Path (Get-Location) $config.TargetDirectory

    if ([IO.Directory]::Exists($projectRoot)) {
      if ($config.Overwrite) {
        [TauriCraft]::EmptyDirectory($projectRoot)
      } elseif (![TauriCraft]::IsDirectoryEmpty($projectRoot)) {
        throw "Target directory '$projectRoot' is not empty. Use -Force to overwrite."
      }
    } else {
      New-Item -Path $projectRoot -ItemType Directory -Force | Out-Null
    }

    $config.TargetDirectory = $projectRoot
  }

  # Template copying method
  static [void] CopyTemplateFiles([ProjectConfig] $config, [string] $moduleRoot) {
    $templateDir = Join-Path $moduleRoot "Private\templates\$($config.Framework.Name)"
    $sharedDir = Join-Path $moduleRoot "Private\templates\.shared"

    if (![IO.Directory]::Exists($templateDir)) {
      throw "Template directory not found: $templateDir"
    }

    Write-Host "Scaffolding project in $($config.TargetDirectory)" -ForegroundColor Gray

    # Copy template files (excluding configuration files that will be processed separately)
    $templateFiles = Get-ChildItem $templateDir -Recurse -File | Where-Object {
      $_.Name -notin @("package.json", "tauri.conf.json", "Cargo.toml")
    }

    foreach ($file in $templateFiles) {
      $relativePath = $file.FullName.Substring($templateDir.Length + 1)
      $targetName = [TauriCraft]::RenameFiles[$file.Name]
      if ([string]::IsNullOrEmpty($targetName)) {
        $targetName = $file.Name
        $targetPath = Join-Path $config.TargetDirectory $relativePath
      } else {
        $targetPath = Join-Path $config.TargetDirectory $targetName
      }

      $targetDir = Split-Path $targetPath -Parent
      if (![IO.Directory]::Exists($targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
      }

      Copy-Item $file.FullName $targetPath -Force
    }

    # Copy shared files (except for SvelteKit)
    if ($config.Framework.Name -ne "sveltekit" -and [IO.Directory]::Exists($sharedDir)) {
      $sharedFiles = Get-ChildItem $sharedDir -Recurse
      foreach ($file in $sharedFiles) {
        $relativePath = $file.FullName.Substring($sharedDir.Length + 1)
        $targetPath = Join-Path $config.TargetDirectory $relativePath
        $targetDir = Split-Path $targetPath -Parent

        if (![IO.Directory]::Exists($targetDir)) {
          New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
        }

        if ($file.PSIsContainer) {
          if (![IO.Directory]::Exists($targetPath)) {
            New-Item -Path $targetPath -ItemType Directory -Force | Out-Null
          }
        } else {
          Copy-Item $file.FullName $targetPath -Force
        }
      }
    }
  }

  # Configuration file processing method
  static [void] ProcessConfigurationFiles([ProjectConfig] $config, [string] $moduleRoot) {
    $templateDir = Join-Path $moduleRoot "Private\templates\$($config.Framework.Name)"

    # Process package.json
    [TauriCraft]::ProcessPackageJson($config, $templateDir)

    # Process tauri.conf.json
    [TauriCraft]::ProcessTauriConfig($config, $templateDir)

    # Process Cargo.toml
    [TauriCraft]::ProcessCargoToml($config, $moduleRoot)

    # Process GitHub Actions release.yml
    [TauriCraft]::ProcessReleaseWorkflow($config, $moduleRoot)
  }

  # Package.json processing
  static [void] ProcessPackageJson([ProjectConfig] $config, [string] $templateDir) {
    $packageJsonPath = [IO.Path]::Combine($templateDir, "package.json")
    if ([IO.Path]::Exists($packageJsonPath)) {
      $packageJson = Get-Content $packageJsonPath -Raw | ConvertFrom-Json
      $packageJson.name = $config.PackageName

      $targetPath = Join-Path $config.TargetDirectory "package.json"
      $packageJson | ConvertTo-Json -Depth 10 | Set-Content $targetPath -Encoding UTF8
    }
  }

  # Tauri configuration processing
  static [void] ProcessTauriConfig([ProjectConfig] $config, [string] $templateDir) {
    $tauriConfigPath = Join-Path $templateDir "src-tauri\tauri.conf.json"
    if ([IO.Path]::Exists($tauriConfigPath)) {
      $tauriConfig = Get-Content $tauriConfigPath -Raw | ConvertFrom-Json

      # Update the product name and window title based on the actual structure
      if ($tauriConfig.productName) {
        $tauriConfig.productName = $config.PackageName
      }

      if ($tauriConfig.app -and $tauriConfig.app.windows -and $tauriConfig.app.windows.Count -gt 0) {
        $tauriConfig.app.windows[0].title = $config.PackageName
      }

      $targetDir = Join-Path $config.TargetDirectory "src-tauri"
      if (![IO.Directory]::Exists($targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
      }

      $targetPath = Join-Path $targetDir "tauri.conf.json"
      $tauriConfig | ConvertTo-Json -Depth 10 | Set-Content $targetPath -Encoding UTF8
    }
  }

  # Cargo.toml processing
  static [void] ProcessCargoToml([ProjectConfig] $config, [string] $moduleRoot) {
    $sharedCargoPath = Join-Path $moduleRoot "Private\templates\.shared\src-tauri\Cargo.toml"

    if ([IO.Path]::Exists($sharedCargoPath)) {
      $cargoContent = Get-Content $sharedCargoPath -Raw
      $updatedContent = $cargoContent -replace 'name\s*=\s*"tauri-ui"', "name = `"$($config.PackageName)`""

      $targetDir = Join-Path $config.TargetDirectory "src-tauri"
      if (![IO.Directory]::Exists($targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
      }

      $targetPath = Join-Path $targetDir "Cargo.toml"
      Set-Content $targetPath $updatedContent -Encoding UTF8
    }
  }

  # GitHub Actions release workflow processing
  static [void] ProcessReleaseWorkflow([ProjectConfig] $config, [string] $moduleRoot) {
    $releaseYmlPath = Join-Path $moduleRoot "Private\templates\.shared\.github\workflows\release.yml"

    if ([IO.Path]::Exists($releaseYmlPath)) {
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

      $targetDir = Join-Path $config.TargetDirectory ".github\workflows"
      if (![IO.Directory]::Exists($targetDir)) {
        New-Item -Path $targetDir -ItemType Directory -Force | Out-Null
      }

      $targetPath = Join-Path $targetDir "release.yml"
      Set-Content $targetPath $updatedContent -Encoding UTF8
    }
  }

  # Completion instructions
  static [void] ShowCompletionInstructions([ProjectConfig] $config) {
    $relativePath = Resolve-Path $config.TargetDirectory -Relative

    Write-Host "`nDone. Now run:" -ForegroundColor Green

    if ($config.TargetDirectory -ne (Get-Location).Path) {
      if ($relativePath.Contains(" ")) {
        Write-Host "  cd `"$relativePath`"" -ForegroundColor Cyan
      } else {
        Write-Host "  cd $relativePath" -ForegroundColor Cyan
      }
    }

    switch ($config.PackageManager) {
      "yarn" {
        Write-Host "  yarn" -ForegroundColor Cyan
        Write-Host "  yarn tauri dev" -ForegroundColor Cyan
      }
      "pnpm" {
        Write-Host "  pnpm i" -ForegroundColor Cyan
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
}
#endregion Classes

# Types that will be available to users when they import the module.
$typestoExport = @(
  [TauriCraft],
  [Framework],
  [TargetOSConfig],
  [ProjectConfig],
  [FrameworkType],
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
