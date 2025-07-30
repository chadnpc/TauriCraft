# TauriCraft Comprehensive docs

## Table of Contents

- [Features](#features)
- [Installation](#installation)
- [Basic Usage](#basic-usage)
- [Advanced Usage](#advanced-usage)
- [Logging](#logging)
- [API Reference](#api-reference)
- [Examples](#examples)
- [Troubleshooting](#troubleshooting)

## Features

### ✅ Core Functionality

- [x] **Interactive project creation** with user-friendly prompts
- [x] **Non-interactive mode** with full parameter support
- [x] **Framework selection**: Vite + React, Next.js, SvelteKit
- [x] **Target OS selection** for GitHub Actions (Windows, macOS, Linux)
- [x] **Project name and package name validation** with npm standards
- [x] **Directory overwrite handling** with safety checks
- [x] **Template file copying** with recursive directory support
- [x] **Configuration file processing** (package.json, tauri.conf.json, Cargo.toml)
- [x] **GitHub Actions workflow configuration** for cross-platform releases
- [x] **Package manager detection** (npm, yarn, pnpm)
- [x] **Completion instructions** with next steps

### ✅ Advanced Features

- [x] **Comprehensive logging** with cliHelper.logger integration
- [x] **Directory validation and formatting** with path normalization
- [x] **Package name validation and conversion** to npm-compliant names
- [x] **File copying and directory operations** with error handling
- [x] **Empty directory detection** with .git folder awareness
- [x] **Package manager detection** from environment variables

### ✅ PowerShell Integration

- [x] **Type accelerators** for easy class access (`[TauriCraft]`, `[Framework]`, etc.)
- [x] **Parameter validation** with ValidateSet attributes
- [x] **Comprehensive help documentation** with examples
- [x] **Error handling** with meaningful messages and logging
- [x] **PowerShell-native prompting** and user interaction
- [x] **Proper module structure** with Public/Private separation
- [x] **Resource management** with automatic logger disposal

## Installation

### From PowerShell Gallery

```powershell
Install-Module TauriCraft -Scope CurrentUser
```

### Prerequisites

The module automatically installs these dependencies:
- `cliHelper.logger` - For comprehensive logging
- `PsModuleBase` - For base class functionality

### Verification

```powershell
Import-Module TauriCraft
Get-Command -Module TauriCraft
```

Expected output:
```
CommandType     Name                Version    Source
-----------     ----                -------    ------
Function        Get-TauriTemplate   0.1.0      TauriCraft
Function        New-TauriProject    0.1.0      TauriCraft
```

## Basic Usage

### Interactive Mode (Recommended for Beginners)

The interactive mode guides you through the project creation process with prompts:

```powershell
Import-Module TauriCraft
New-TauriProject
```

This will prompt you for:
1. **Project name** (default: "tauri-ui")
2. **Package name** (auto-generated from project name)
3. **Framework selection** (Vite + React, Next.js, or SvelteKit)
4. **Target operating systems** for GitHub Actions
5. **Overwrite confirmation** if directory exists

### Non-Interactive Mode

For automation or when you know exactly what you want:

```powershell
# Basic project creation
New-TauriProject -Name "my-tauri-app" -Framework "vite"

# With specific OS targets
New-TauriProject -Name "my-app" -Framework "next" -TargetOS @("windows-latest", "ubuntu-latest")

# Force overwrite existing directory
New-TauriProject -Name "existing-dir" -Framework "sveltekit" -Force
```

### Template Information

```powershell
# List available frameworks
Get-TauriTemplate

# Show frameworks with OS target information
Get-TauriTemplate -ShowTargetOS

# Show specific framework details
Get-TauriTemplate -Framework "vite"
```

## Advanced Usage

### Custom Package Manager

TauriCraft automatically detects your package manager from environment variables, but you can override it:

```powershell
# Use pnpm
New-TauriProject -Name "my-app" -Framework "vite" -PackageManager "pnpm"

# Use yarn
New-TauriProject -Name "my-app" -Framework "next" -PackageManager "yarn"
```

### Custom Package Names

When your project name doesn't make a valid npm package name:

```powershell
# Project name with spaces/special characters
New-TauriProject -Name "My Awesome App" -PackageName "my-awesome-app" -Framework "vite"
```

### Complete Parameter Example

```powershell
New-TauriProject `
  -Name "enterprise-desktop-app" `
  -Framework "next" `
  -PackageName "enterprise-desktop-app" `
  -TargetOS @("windows-latest", "macos-latest") `
  -PackageManager "yarn" `
  -Force
```

## Logging

TauriCraft includes comprehensive logging using the `cliHelper.logger` module. The logger provides detailed information about the project creation process.

### Log Levels

- **DEBUG**: Detailed operation information (file copying, path resolution)
- **INFO**: General progress information (project creation steps)
- **WARN**: Non-critical issues (missing optional files)
- **ERROR**: Critical errors that prevent project creation

### Accessing Logs

The logger is automatically initialized when you use TauriCraft functions. You can access it directly:

```powershell
# The logger is available as a static property
[TauriCraft]::Logger

# Read log entries (if JSON appender is added)
[TauriCraft]::Logger | Read-LogEntries -Type Json
```

### Logger Management

The logger is automatically disposed when the module is unloaded, ensuring proper resource cleanup:

```powershell
# Manual disposal (usually not needed)
[TauriCraft]::DisposeLogger()
```

## File Structure

### Module Structure

```
TauriCraft/
├── TauriCraft.psm1              # Main module with classes and logging
├── TauriCraft.psd1              # Module manifest
├── Public/
│   ├── New-TauriProject.ps1     # Main scaffolding function
│   └── Get-TauriTemplate.ps1    # Template listing function
├── Private/
│   └── templates/               # Template files
│       ├── vite/                # Vite + React template
│       ├── next/                # Next.js template
│       ├── sveltekit/           # SvelteKit template
│       └── .shared/             # Shared files (GitHub Actions, etc.)
├── docs/
│   └── Readme.md               # This documentation
└── README.md                   # Main project README
```

### Generated Project Structure

After creating a project, you'll have:

```
my-tauri-app/
├── src/                        # Frontend source code
│   ├── components/             # React/Svelte components
│   ├── styles/                 # CSS/styling files
│   └── App.tsx                 # Main application component
├── src-tauri/                  # Tauri backend
│   ├── src/                    # Rust source code
│   ├── icons/                  # Application icons
│   ├── Cargo.toml              # Rust dependencies
│   └── tauri.conf.json         # Tauri configuration
├── .github/
│   └── workflows/
│       └── release.yml         # GitHub Actions for releases
├── public/                     # Static assets
├── package.json                # Node.js dependencies and scripts
├── tailwind.config.js          # Tailwind CSS configuration
├── tsconfig.json               # TypeScript configuration
└── vite.config.ts              # Vite configuration (for Vite template)
```

## API Reference

### Functions

#### New-TauriProject

Creates a new Tauri desktop application project.

**Syntax:**
```powershell
New-TauriProject [[-ProjectName] <String>] [-Framework <String>] [-PackageName <String>]
                 [-TargetOS <String[]>] [-Force] [-Interactive] [-PackageManager <String>]
```

**Parameters:**

| Parameter | Type | Description | Default |
|-----------|------|-------------|---------|
| `ProjectName` | String | Name of the project directory | Prompted if not provided |
| `Framework` | String | Framework to use (`vite`, `next`, `sveltekit`) | Prompted if not provided |
| `PackageName` | String | Package name for package.json | Auto-generated from ProjectName |
| `TargetOS` | String[] | Target OS for GitHub Actions | All platforms |
| `Force` | Switch | Overwrite existing directory | False |
| `Interactive` | Switch | Force interactive mode | False |
| `PackageManager` | String | Package manager (`npm`, `yarn`, `pnpm`) | Auto-detected |

**Examples:**
```powershell
# Interactive mode
New-TauriProject

# Quick project creation
New-TauriProject -Name "my-app" -Framework "vite"

# Full specification
New-TauriProject -Name "desktop-app" -Framework "next" -TargetOS @("windows-latest") -Force
```

#### Get-TauriTemplate

Lists available Tauri project templates and frameworks.

**Syntax:**
```powershell
Get-TauriTemplate [[-Framework] <String>] [-ShowTargetOS]
```

**Parameters:**

| Parameter | Type | Description |
|-----------|------|-------------|
| `Framework` | String | Filter by specific framework |
| `ShowTargetOS` | Switch | Include target OS information |

**Examples:**
```powershell
# List all templates
Get-TauriTemplate

# Show specific framework
Get-TauriTemplate -Framework "vite"

# Include OS information
Get-TauriTemplate -ShowTargetOS
```

### Classes

#### TauriCraft

Main static class containing all scaffolding functionality.

**Static Properties:**
- `$Frameworks`: Array of available frameworks
- `$TargetOperatingSystems`: Array of supported OS targets
- `$Logger`: Logging instance

**Static Methods:**
- `CreateProject([ProjectConfig], [string])`: Main project creation method
- `GetTemplates()`: Returns array of template names
- `GetAllOSTargets()`: Returns array of OS target values
- `ValidateConfig([ProjectConfig])`: Validates project configuration
- `DisposeLogger()`: Disposes logging resources

#### Framework

Represents a UI framework option.

**Properties:**
- `Name`: Framework identifier (e.g., "vite")
- `Display`: Human-readable name (e.g., "⚡Vite + React")
- `Color`: Display color

#### ProjectConfig

Configuration container for project creation.

**Properties:**
- `ProjectName`: Name of the project
- `PackageName`: NPM package name
- `Framework`: Selected framework object
- `ReleaseOS`: Array of target operating systems
- `Overwrite`: Whether to overwrite existing directory
- `TargetDirectory`: Full path to project directory
- `PackageManager`: Package manager to use

## Examples

### Complete Workflow Examples

#### Creating a React Desktop App

```powershell
# Step 1: Create the project
New-TauriProject -Name "react-desktop-app" -Framework "vite"

# Step 2: Navigate and install dependencies
cd react-desktop-app
npm install

# Step 3: Run in development mode
npm run tauri dev

# Step 4: Build for production
npm run tauri build
```

#### Creating a Next.js App with Custom Configuration

```powershell
# Create with specific settings
New-TauriProject `
  -Name "nextjs-enterprise-app" `
  -Framework "next" `
  -PackageName "enterprise-desktop" `
  -TargetOS @("windows-latest", "macos-latest") `
  -PackageManager "yarn" `
  -Force

# Navigate and setup
cd nextjs-enterprise-app
yarn install
yarn tauri dev
```

#### Batch Project Creation

```powershell
# Create multiple projects with different frameworks
$projects = @(
  @{ Name = "vite-app"; Framework = "vite" },
  @{ Name = "next-app"; Framework = "next" },
  @{ Name = "svelte-app"; Framework = "sveltekit" }
)

foreach ($project in $projects) {
  New-TauriProject -Name $project.Name -Framework $project.Framework -Force
  Write-Host "Created $($project.Name) with $($project.Framework)" -ForegroundColor Green
}
```

## Troubleshooting

### Common Issues

#### "Template directory not found"

**Problem:** The module can't find the template files.

**Solution:**
```powershell
# Reinstall the module
Uninstall-Module TauriCraft
Install-Module TauriCraft -Force
```

#### "Target directory is not empty"

**Problem:** Trying to create a project in an existing directory.

**Solutions:**
```powershell
# Use -Force to overwrite
New-TauriProject -Name "my-app" -Framework "vite" -Force

# Or choose a different directory name
New-TauriProject -Name "my-app-v2" -Framework "vite"
```

#### "Invalid package name"

**Problem:** Project name contains invalid characters for npm packages.

**Solution:**
```powershell
# Specify a custom package name
New-TauriProject -Name "My App!" -PackageName "my-app" -Framework "vite"
```

#### PowerShell Execution Policy Issues

**Problem:** Cannot run PowerShell scripts.

**Solution:**
```powershell
# Set execution policy for current user
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

### Debug Information

#### Enable Verbose Logging

```powershell
# The logger is set to INFO level by default
# To see DEBUG messages, you can modify the logger level
[TauriCraft]::InitializeLogger()
[TauriCraft]::Logger.MinLevel = 0  # DEBUG level
```

#### Check Module Information

```powershell
# Get module details
Get-Module TauriCraft -ListAvailable

# Check exported functions
Get-Command -Module TauriCraft

# Verify dependencies
Get-Module cliHelper.logger, PsModuleBase -ListAvailable
```

#### Manual Template Verification

```powershell
# Check if templates exist
$modulePath = (Get-Module TauriCraft).ModuleBase
Test-Path "$modulePath\Private\templates\vite"
Test-Path "$modulePath\Private\templates\next"
Test-Path "$modulePath\Private\templates\sveltekit"
```

### Getting Help

#### Built-in Help

```powershell
# Function help
Get-Help New-TauriProject -Full
Get-Help Get-TauriTemplate -Examples

# Parameter information
Get-Help New-TauriProject -Parameter Framework
```

#### Log Analysis

```powershell
# Check recent log entries
[TauriCraft]::Logger | Read-LogEntries -Type Json | Select-Object -Last 10
```

## Verification Commands

### Basic Verification

```powershell
# Test module loading
Import-Module TauriCraft -Force

# Verify exported functions
Get-Command -Module TauriCraft

# Test template listing
Get-TauriTemplate

# Test framework detection
[TauriCraft]::GetTemplates()

# Test OS targets
[TauriCraft]::GetAllOSTargets()
```

### Advanced Verification

```powershell
# Test logging functionality
[TauriCraft]::InitializeLogger()
[TauriCraft]::Logger.LogInfoLine("Test message")

# Verify template paths
$modulePath = (Get-Module TauriCraft).ModuleBase
Get-ChildItem "$modulePath\Private\templates" -Directory

# Test configuration validation
$config = [ProjectConfig]::new()
$config.ProjectName = "test"
$config.PackageName = "test"
$config.Framework = [TauriCraft]::Frameworks[0]
[TauriCraft]::ValidateConfig($config)
```

### Performance Testing

```powershell
# Measure project creation time
Measure-Command {
  New-TauriProject -Name "perf-test" -Framework "vite" -Force
}

# Clean up
Remove-Item "perf-test" -Recurse -Force
```
