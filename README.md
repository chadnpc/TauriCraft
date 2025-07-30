
# [TauriCraft](https://www.powershellgallery.com/packages/TauriCraft)

🔥 PowerShell module to create Tauri-v2 🦀 desktop apps.

[![Build Module](https://github.com/chadnpc/TauriCraft/actions/workflows/build_module.yaml/badge.svg)](https://github.com/chadnpc/TauriCraft/actions/workflows/build_module.yaml)
[![Downloads](https://img.shields.io/powershellgallery/dt/TauriCraft.svg?style=flat&logo=powershell&color=blue)](https://www.powershellgallery.com/packages/TauriCraft)

🚀 **Supported Frameworks**: Vite + React, Next.js, and SvelteKit templates

🔧 **auto Configures**: package.json, tauri.conf.json, and Cargo.toml

## Installation

```PowerShell
Install-Module TauriCraft -Scope CurrentUser
```

## Usage

### Interactive

```PowerShell
Import-Module TauriCraft
New-TauriProject
```

This will guide you through the project creation process with interactive prompts.

### Non-Interactive

```PowerShell
# Create a Vite + React project
New-TauriProject -Name "my-tauri-app" -Framework "vite"

# Create a Next.js project with specific OS targets
New-TauriProject -Name "my-app" -Framework "next" -TargetOS @("windows-latest", "ubuntu-latest")

# Force overwrite existing directory
New-TauriProject -Name "existing-dir" -Framework "sveltekit" -Force
```

### List Templates

```PowerShell
# Show available frameworks
Get-TauriTemplate

# Show frameworks with OS target information
Get-TauriTemplate -ShowTargetOS
```

```PowerShell
New-TauriProject -Name "my-app" -Framework "vite" -PackageManager "pnpm"
```

```PowerShell
New-TauriProject -Name "My App" -PackageName "my-custom-app" -Framework "next"
```

### Or use all the Params

```PowerShell
New-TauriProject `
  -Name "awesome-app" `
  -Framework "vite" `
  -PackageName "awesome-app" `
  -TargetOS @("windows-latest", "macos-latest") `
  -PackageManager "yarn" `
  -Force
```

## Available Templates

| Framework | Description | Template Name |
|-----------|-------------|---------------|
| ⚡ Vite + React | Fast React development with Vite | `vite` |
| ▲ Next.js | Full-stack React framework | `next` |
| ⚡ Vite + SvelteKit | Modern Svelte framework | `sveltekit` |

## What Gets Created

When you create a new project, TauriCraft will:

1. **Copy Template Files**: All necessary files for your chosen framework
2. **Update Configuration**:
   - `package.json`: Sets the correct package name
   - `tauri.conf.json`: Updates product name and window title
   - `Cargo.toml`: Sets the Rust package name
   - `.github/workflows/release.yml`: Configures CI/CD for selected platforms
3. **Provide Instructions**: Shows you the next steps to run your app

## Project Structure

After creation, your project will have this structure:

```
my-tauri-app/
├── src/                     # Frontend source code
├── src-tauri/              # Tauri backend
│   ├── src/                # Rust source code
│   ├── Cargo.toml          # Rust dependencies
│   └── tauri.conf.json     # Tauri configuration
├── .github/workflows/      # GitHub Actions
├── package.json            # Node.js dependencies
└── ...                     # Framework-specific files
```

## Examples

### Create a React App

```PowerShell
New-TauriProject -Name "react-desktop-app" -Framework "vite"
cd react-desktop-app
npm install
npm run tauri dev
```

### Create a Next.js App for Windows Only

```PowerShell
New-TauriProject `
  -Name "nextjs-windows-app" `
  -Framework "next" `
  -TargetOS @("windows-latest") `
  -PackageManager "pnpm"
```

### Interactive Setup

```PowerShell
New-TauriProject -Interactive
```

## Documentation

For more detailed docs and examples, see [docs/Readme.md](docs/Readme.md).

## Contributing

Pull Requests are welcome!

## License

This project is licensed under the [WTFPL License](LICENSE).
