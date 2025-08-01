function New-TauriProject {
  <#
  .SYNOPSIS
    Creates a new Tauri Next.js desktop application project using PowerShell.

  .DESCRIPTION
    New-TauriProject scaffolds a new Tauri v2 desktop application with Next.js frontend and configures GitHub Actions for
    cross-platform releases. This is a simplified version focused on Next.js only.

  .PARAMETER ProjectName
    The name of the project directory to create. If not specified, you'll be prompted to enter one.

  .PARAMETER PackageName
    The package name for package.json. If not specified, it will be derived from the project name.

  .PARAMETER TargetOS
    Array of target operating systems for GitHub Actions. Valid options are: 'windows-latest', 'macos-latest', 'ubuntu-latest'.
    Default is all three platforms.

  .PARAMETER Force
    Overwrite the target directory if it already exists and is not empty.

  .PARAMETER Interactive
    Run in interactive mode with prompts for all options (default behavior).

  .PARAMETER PackageManager
    The package manager to use. Valid options are: 'npm', 'yarn', 'pnpm'. Default is 'npm'.

  .EXAMPLE
    New-TauriProject

    Creates a new Tauri Next.js project with interactive prompts for all options.

  .EXAMPLE
    New-TauriProject -Name "my-tauri-app"

    Creates a new Tauri Next.js project named "my-tauri-app".

  .EXAMPLE
    New-TauriProject -Name "my-app" -TargetOS @("windows-latest", "ubuntu-latest") -Force

    Creates a new Tauri Next.js project targeting only Windows and Linux, overwriting any existing directory.

  .NOTES
    This function uses the Next.js template from the module's Private/nextjs-template directory.
    The function will copy template files, process configuration files, and set up the project structure.
  #>
  [CmdletBinding(DefaultParameterSetName = 'Interactive', SupportsShouldProcess = $true)]
  param(
    [Parameter(Position = 0)]
    [Alias('Name', 'n')]
    [string]$ProjectName,

    [Parameter()]
    [Alias('pn')]
    [string]$PackageName,

    [Parameter()]
    [ValidateSet('windows-latest', 'macos-latest', 'ubuntu-latest')]
    [alias('os', 'target')]
    [string[]]$TargetOS = @('windows-latest', 'macos-latest', 'ubuntu-latest'),

    [Parameter()]
    [switch]$Force,

    [Parameter(ParameterSetName = 'Interactive')]
    [switch]$Interactive,

    [Parameter()]
    [ValidateSet('npm', 'yarn', 'pnpm')]
    [Alias('pm')]
    [string]$PackageManager
  )

  try {
    # Detect package manager if not specified
    if ([string]::IsNullOrWhiteSpace($PackageManager)) {
      $pkgInfo = [TauriCraft]::DetectPackageManager()
      $PackageManager = $pkgInfo.name
    }

    # Interactive mode or missing required parameters
    if ($Interactive -or [string]::IsNullOrWhiteSpace($ProjectName)) {
      $config = Get-InteractiveProjectConfig -ProjectName $ProjectName -PackageName $PackageName -TargetOS $TargetOS -Force:$Force -PackageManager $PackageManager
    } else {
      # Non-interactive mode with all parameters provided
      $config = [ProjectConfig]::new()
      $config.ProjectName = $ProjectName
      $config.TargetDirectory = [TauriCraft]::FormatTargetDirectory($ProjectName)
      if ([string]::IsNullOrWhiteSpace($config.TargetDirectory)) {
        $config.TargetDirectory = [TauriCraft]::DefaultTargetDir
      }

      # No framework selection needed - using Next.js only

      # Set package name
      if ([string]::IsNullOrWhiteSpace($PackageName)) {
        $config.PackageName = [TauriCraft]::ToValidPackageName($config.ProjectName)
      } else {
        $config.PackageName = $PackageName
      }

      # Validate package name
      if (![TauriCraft]::IsValidPackageName($config.PackageName)) {
        throw [System.InvalidOperationException]::new("Invalid package name: $($config.PackageName). Package names must follow npm naming conventions.")
      }

      $config.ReleaseOS = $TargetOS
      $config.Overwrite = $Force
      $config.PackageManager = $PackageManager
    }

    # Create the project
    $moduleRoot = [IO.Path]::GetDirectoryName($PSScriptRoot)
    if ($PSCmdlet.ShouldProcess("$moduleRoot", "Create Tauri project")) {
      [TauriCraft]::CreateProject($config, $moduleRoot)
    }
  } catch {
    Write-Error "Failed to create Tauri Next.js project: $($_.Exception.Message)"
    return
  }
}

function Get-InteractiveProjectConfig {
  param(
    [string]$ProjectName,
    [string]$PackageName,
    [string[]]$TargetOS,
    [bool]$Force,
    [string]$PackageManager
  )

  $config = [ProjectConfig]::new()
  $config.PackageManager = $PackageManager

  # Project name prompt
  if ([string]::IsNullOrWhiteSpace($ProjectName)) {
    do {
      $ProjectName = Read-Host "Project name [$([TauriCraft]::DefaultTargetDir)]"
      if ([string]::IsNullOrWhiteSpace($ProjectName)) {
        $ProjectName = [TauriCraft]::DefaultTargetDir
      }
      $ProjectName = [TauriCraft]::FormatTargetDirectory($ProjectName)
    } while ([string]::IsNullOrWhiteSpace($ProjectName))
  }

  $config.ProjectName = $ProjectName
  $config.TargetDirectory = $ProjectName

  # Check if directory exists and prompt for overwrite
  $projectPath = [IO.Path]::Combine((Get-Location) , $config.TargetDirectory)
  if ((Test-Path $projectPath) -and -not [TauriCraft]::IsDirectoryEmpty($projectPath)) {
    if (-not $Force) {
      $overwrite = Read-Host "Target directory '$($config.TargetDirectory)' is not empty. Remove existing files and continue? (y/N)"
      $config.Overwrite = $overwrite -match '^[Yy]'
      if (-not $config.Overwrite) {
        throw "Operation cancelled"
      }
    } else {
      $config.Overwrite = $true
    }
  }

  # Package name
  $defaultPackageName = [TauriCraft]::ToValidPackageName($config.ProjectName)
  if ([string]::IsNullOrWhiteSpace($PackageName)) {
    if (-not [TauriCraft]::IsValidPackageName($defaultPackageName)) {
      do {
        $PackageName = Read-Host "Package name [$defaultPackageName]"
        if ([string]::IsNullOrWhiteSpace($PackageName)) {
          $PackageName = $defaultPackageName
        }
      } while (-not [TauriCraft]::IsValidPackageName($PackageName))
    } else {
      $PackageName = $defaultPackageName
    }
  }
  $config.PackageName = $PackageName

  # Target OS selection
  Write-Host "`nTarget operating systems for GitHub Actions:" -ForegroundColor Yellow
  Write-Host "(Use space to toggle, Enter to confirm)" -ForegroundColor Gray

  $osConfigs = [TauriCraft]::TargetOperatingSystems
  $selectedOS = @()

  foreach ($osConfig in $osConfigs) {
    $default = if ($TargetOS -contains $osConfig.Value) { "Y" } else { "n" }
    $choice = Read-Host "$($osConfig.Title) [$default]"
    if ([string]::IsNullOrWhiteSpace($choice)) {
      $choice = $default
    }
    if ($choice -match '^[Yy]') {
      $selectedOS += $osConfig.Value
    }
  }

  if ($selectedOS.Count -eq 0) {
    Write-Warning "No target OS selected. Using all platforms."
    $selectedOS = [TauriCraft]::GetAllOSTargets()
  }

  $config.ReleaseOS = $selectedOS

  return $config
}