# docs

Extensive usage docs for TauriCraft PowerShell Module.

### ✅ Core Functionality

- [x] Interactive project creation with prompts
- [x] Non-interactive mode with parameters
- [x] Framework selection (Vite + React, Next.js, SvelteKit)
- [x] Target OS selection for GitHub Actions
- [x] Project name and package name validation
- [x] Directory overwrite handling
- [x] Template file copying
- [x] Configuration file processing (package.json, tauri.conf.json, Cargo.toml)
- [x] GitHub Actions workflow configuration
- [x] Package manager detection
- [x] Completion instructions

### ✅ Utility Functions

- [x] Directory validation and formatting
- [x] Package name validation and conversion
- [x] File copying and directory operations
- [x] Empty directory detection
- [x] Package manager detection from environment

### ✅ PowerShell Integration

- [x] Type accelerators for easy class access
- [x] Parameter validation and help documentation
- [x] Error handling with meaningful messages
- [x] PowerShell-native prompting and user interaction
- [x] Proper module structure with Public/Private separation

## Examples

### Interactive Mode
```powershell
# Import the module
Import-Module TauriCraft

# Create project with interactive prompts
New-TauriProject

# List available templates
Get-TauriTemplate
```

### Non-Interactive Mode
```powershell
# Create a Vite + React project
New-TauriProject -ProjectName "my-tauri-app" -Framework "vite"

# Create a Next.js project with specific OS targets
New-TauriProject -ProjectName "my-app" -Framework "next" -TargetOS @("windows-latest", "ubuntu-latest")

# Force overwrite existing directory
New-TauriProject -ProjectName "existing-dir" -Framework "sveltekit" -Force
```

### Advanced Usage
```powershell
# Use specific package manager
New-TauriProject -ProjectName "my-app" -Framework "vite" -PackageManager "pnpm"

# Custom package name
New-TauriProject -ProjectName "My App" -PackageName "my-custom-app" -Framework "next"

# Show available templates with OS information
Get-TauriTemplate -ShowTargetOS
```

## File Structure

```
TauriCraft/
├── TauriCraft.psm1              # Main module file with classes
├── Public/
│   ├── New-TauriProject.ps1     # Main scaffolding function
│   └── Get-TauriTemplate.ps1    # Template listing function
├── Private/
│   └── templates/               # Template files (copied from inspiration)
│       ├── vite/
│       ├── next/
│       ├── sveltekit/
│       └── .shared/
└── CONVERSION_SUMMARY.md        # This file
```

## Technical Implementation Details

### Static Methods in TauriCraft Class
- `CreateProject()`: Main orchestration method
- `ValidateConfig()`: Configuration validation
- `SetupProjectDirectory()`: Directory preparation
- `CopyTemplateFiles()`: Template file copying
- `ProcessConfigurationFiles()`: Config file processing
- `ShowCompletionInstructions()`: User guidance
- Utility methods for file operations and validation

### Configuration Processing
- **package.json**: Updates name field with user-provided package name
- **tauri.conf.json**: Updates window title and product name
- **Cargo.toml**: Updates Rust package name
- **release.yml**: Configures GitHub Actions for selected OS targets

### Error Handling
- Comprehensive parameter validation
- Meaningful error messages for common issues
- Graceful handling of missing templates or files
- User-friendly prompts for overwrite scenarios

## Testing Results ✅

The conversion has been successfully tested with the following scenarios:

### Test 1: Vite + React Template
```powershell
New-TauriProject -ProjectName 'test-project' -Framework 'vite' -TargetOS @('windows-latest') -PackageManager 'npm' -Force
```
**Results:**
- ✅ Project created successfully
- ✅ All template files copied correctly
- ✅ package.json updated with correct name: "test-project"
- ✅ tauri.conf.json updated with productName and window title: "test-project"
- ✅ Cargo.toml updated with correct package name: "test-project"
- ✅ Completion instructions displayed correctly for npm

### Test 2: Next.js Template
```powershell
New-TauriProject -ProjectName 'next-test' -Framework 'next' -TargetOS @('windows-latest', 'ubuntu-latest') -PackageManager 'pnpm' -Force
```
**Results:**
- ✅ Project created successfully
- ✅ All Next.js template files copied correctly
- ✅ Configuration files processed correctly
- ✅ Completion instructions displayed correctly for pnpm

### Test 3: Module Functions
```powershell
Get-TauriTemplate
[TauriCraft]::GetTemplates()
[TauriCraft]::GetAllOSTargets()
```
**Results:**
- ✅ Template listing works correctly
- ✅ Static methods accessible and functional
- ✅ Framework detection working

## Next Steps

1. ✅ **Core Functionality**: All main features implemented and tested
2. ✅ **Template Processing**: All templates copy and process correctly
3. ✅ **Configuration Updates**: package.json, tauri.conf.json, and Cargo.toml update correctly
4. **Documentation**: Add detailed help documentation and examples
5. **Publishing**: Prepare for PowerShell Gallery publication
6. **Cleanup**: Remove the `.tauri-ui-master-inspiration/` folder after verification

## Verification Commands

```powershell
# Test module loading
Import-Module .\TauriCraft.psm1 -Force

# Verify exported functions
Get-Command -Module TauriCraft

# Test template listing
Get-TauriTemplate

# Test framework detection
[TauriCraft]::GetTemplates()

# Test OS targets
[TauriCraft]::GetAllOSTargets()
```

