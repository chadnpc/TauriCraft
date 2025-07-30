function New-TauriProject {
  <#
  .SYNOPSIS
    Creates a new Tauri desktop application project using PowerShell.

  .DESCRIPTION
    New-TauriProject is a PowerShell equivalent of the tauri-ui CLI tool. It scaffolds a new Tauri v2 desktop application
    with your choice of frontend framework (Vite + React, Next.js, or SvelteKit) and configures GitHub Actions for
    cross-platform releases.

  .PARAMETER ProjectName
    The name of the project directory to create. If not specified, you'll be prompted to enter one.

  .PARAMETER Framework
    The frontend framework to use. Valid options are: 'vite', 'next', 'sveltekit'.
    If not specified, you'll be prompted to choose from a list.

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

    Creates a new Tauri project with interactive prompts for all options.

  .EXAMPLE
    New-TauriProject -ProjectName "my-tauri-app" -Framework "vite"

    Creates a new Tauri project named "my-tauri-app" using the Vite + React template.

  .EXAMPLE
    New-TauriProject -ProjectName "my-app" -Framework "next" -TargetOS @("windows-latest", "ubuntu-latest") -Force

    Creates a new Tauri project with Next.js, targeting only Windows and Linux, overwriting any existing directory.

  .NOTES
    This function requires the templates to be available in the module's Private/templates directory.
    The function will copy template files, process configuration files, and set up the project structure.
  #>
  [CmdletBinding(DefaultParameterSetName = 'Interactive', SupportsShouldProcess = $true)]
  param(
    [Parameter(Position = 0)]
    [string]$ProjectName,

    [Parameter()]
    [ValidateSet('vite', 'next', 'sveltekit')]
    [string]$Framework,

    [Parameter()]
    [string]$PackageName,

    [Parameter()]
    [ValidateSet('windows-latest', 'macos-latest', 'ubuntu-latest')]
    [string[]]$TargetOS = @('windows-latest', 'macos-latest', 'ubuntu-latest'),

    [Parameter()]
    [switch]$Force,

    [Parameter(ParameterSetName = 'Interactive')]
    [switch]$Interactive,

    [Parameter()]
    [ValidateSet('npm', 'yarn', 'pnpm')]
    [string]$PackageManager
  )

  try {
    # Detect package manager if not specified
    if ([string]::IsNullOrWhiteSpace($PackageManager)) {
      $pkgInfo = [TauriCraft]::DetectPackageManager()
      $PackageManager = $pkgInfo.name
    }

    # Interactive mode or missing required parameters
    if ($Interactive -or [string]::IsNullOrWhiteSpace($ProjectName) -or [string]::IsNullOrWhiteSpace($Framework)) {
      $config = Get-InteractiveProjectConfig -ProjectName $ProjectName -Framework $Framework -PackageName $PackageName -TargetOS $TargetOS -Force:$Force -PackageManager $PackageManager
    } else {
      # Non-interactive mode with all parameters provided
      $config = [ProjectConfig]::new()
      $config.ProjectName = $ProjectName
      $config.TargetDirectory = [TauriCraft]::FormatTargetDirectory($ProjectName)
      if ([string]::IsNullOrWhiteSpace($config.TargetDirectory)) {
        $config.TargetDirectory = [TauriCraft]::DefaultTargetDir
      }

      # Find the framework object
      $frameworkObj = [TauriCraft]::Frameworks | Where-Object { $_.Name -eq $Framework }
      if ($null -eq $frameworkObj) {
        throw [System.InvalidOperationException]::new("Invalid framework: $Framework. Valid options: $([TauriCraft]::GetTemplates() -join ', ')")
      }
      $config.Framework = $frameworkObj

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
    Write-Error "Failed to create Tauri project: $($_.Exception.Message)"
    return
  }
}