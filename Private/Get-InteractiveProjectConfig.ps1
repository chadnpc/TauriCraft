function Get-InteractiveProjectConfig {
  param(
    [string]$ProjectName,
    [string]$Framework,
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
  $projectPath = [IO.Path]::Combine((Get-Location), $config.TargetDirectory)
  if ([IO.Directory]::Exists($projectPath) -and ![TauriCraft]::IsDirectoryEmpty($projectPath)) {
    if (!$Force) {
      $overwrite = Read-Host "Target directory '$($config.TargetDirectory)' is not empty. Remove existing files and continue? (y/N)"
      $config.Overwrite = $overwrite -match '^[Yy]'
      if (!$config.Overwrite) {
        throw [OperationStoppedException]::new("Operation cancelled")
      }
    } else {
      $config.Overwrite = $true
    }
  }

  # Package name
  $defaultPackageName = [TauriCraft]::ToValidPackageName($config.ProjectName)
  if ([string]::IsNullOrWhiteSpace($PackageName)) {
    if (![TauriCraft]::IsValidPackageName($defaultPackageName)) {
      do {
        $PackageName = Read-Host "Package name [$defaultPackageName]"
        if ([string]::IsNullOrWhiteSpace($PackageName)) {
          $PackageName = $defaultPackageName
        }
      } while (![TauriCraft]::IsValidPackageName($PackageName))
    } else {
      $PackageName = $defaultPackageName
    }
  }
  $config.PackageName = $PackageName

  # Framework selection
  if ([string]::IsNullOrWhiteSpace($Framework)) {
    Write-Host "`nSelect a framework:" -ForegroundColor Yellow
    $frameworks = [TauriCraft]::Frameworks
    for ($i = 0; $i -lt $frameworks.Count; $i++) {
      Write-Host "  $($i + 1). $($frameworks[$i].Display)" -ForegroundColor Cyan
    }

    do {
      $selection = Read-Host "Enter your choice (1-$($frameworks.Count))"
      $selectionNum = 0
      $validSelection = [int]::TryParse($selection, [ref]$selectionNum) -and $selectionNum -ge 1 -and $selectionNum -le $frameworks.Count
    } while (!$validSelection)

    $config.Framework = $frameworks[$selectionNum - 1]
  } else {
    $frameworkObj = [TauriCraft]::Frameworks | Where-Object { $_.Name -eq $Framework }
    if ($null -eq $frameworkObj) {
      throw "Invalid framework: $Framework"
    }
    $config.Framework = $frameworkObj
  }

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
