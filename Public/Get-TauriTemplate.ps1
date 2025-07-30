function Get-TauriTemplate {
  <#
    .SYNOPSIS
    Lists available Tauri project templates and frameworks.

    .DESCRIPTION
    Get-TauriTemplate displays information about available Tauri project templates,
    including supported frameworks and target operating systems.

    .PARAMETER Framework
    Filter results to show only information about a specific framework.
    Valid options are: 'vite', 'next', 'sveltekit'.

    .PARAMETER ShowTargetOS
    Include information about supported target operating systems for GitHub Actions.

    .EXAMPLE
    Get-TauriTemplate

    Lists all available frameworks and their details.

    .EXAMPLE
    Get-TauriTemplate -Framework "vite"

    Shows details for the Vite + React template only.

    .EXAMPLE
    Get-TauriTemplate -ShowTargetOS

    Lists all frameworks and includes target OS information.

    .NOTES
    This function provides information about the templates available in the TauriCraft module.
  #>
  [CmdletBinding()]
  param(
    [Parameter()]
    [ValidateSet('vite', 'next', 'sveltekit')]
    [string]$Framework,

    [Parameter()]
    [switch]$ShowTargetOS
  )

  Write-Host "TauriCraft - Available Templates" -ForegroundColor Green
  Write-Host "================================" -ForegroundColor Green
  Write-Host ""

  $frameworks = [TauriCraft]::Frameworks

  if (![string]::IsNullOrWhiteSpace($Framework)) {
    $frameworks = $frameworks | Where-Object { $_.Name -eq $Framework }
    if ($frameworks.Count -eq 0) {
      Write-Warning "Framework '$Framework' not found."
      return
    }
  }

  foreach ($fw in $frameworks) {
    Write-Host "Framework: " -NoNewline -ForegroundColor Yellow
    Write-Host $fw.Display -ForegroundColor Cyan
    Write-Host "  Name: " -NoNewline -ForegroundColor Gray
    Write-Host $fw.Name -ForegroundColor White
    Write-Host "  Template: " -NoNewline -ForegroundColor Gray
    Write-Host "Private/templates/$($fw.Name)" -ForegroundColor White
    Write-Host ""
  }

  if ($ShowTargetOS) {
    Write-Host "Target Operating Systems" -ForegroundColor Green
    Write-Host "========================" -ForegroundColor Green
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
  Write-Host "  New-TauriProject -ProjectName 'my-app' -Framework 'vite'" -ForegroundColor Cyan
  Write-Host "  New-TauriProject -Interactive" -ForegroundColor Cyan
  Write-Host ""
}