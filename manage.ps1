# PowerShell script to manage Neovim configuration and create/unpack an offline package

# Define paths
$initLuaPath = "$env:LOCALAPPDATA\nvim\init.lua"
$plugVimPath = "$env:LOCALAPPDATA\nvim-data\site\autoload\plug.vim"
$pluggedPath = "$env:LOCALAPPDATA\nvim-data\plugged"
$defaultPackageName = "nvim-dotfile-offline.zip"

# Function to show usage
function Show-Usage {
    Write-Host "Usage: $($MyInvocation.MyCommand.Name) {create-pack|unpack [path_to_package]} [-y]"
    Write-Host "  create-pack              Create an offline package of Neovim configuration"
    Write-Host "  unpack [path_to_package] Extract and install the offline package"
    Write-Host "                           If path is not specified, uses $defaultPackageName"
    Write-Host "  -y                       Force overwrite without prompting"
}

# Function to download plug.vim
function Download-PlugVim {
    if (Test-Path $plugVimPath) {
        Write-Host "plug.vim already exists. Skipping download."
    }
    else {
        Write-Host "Downloading plug.vim..."
        $plugVimUrl = "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim"
        New-Item -Path (Split-Path $plugVimPath) -ItemType Directory -Force | Out-Null
        Invoke-WebRequest -Uri $plugVimUrl -OutFile $plugVimPath
    }
}

# Function to run PlugInstall
function Run-PlugInstall {
    if (Test-Path $pluggedPath) {
        if ((Get-ChildItem $pluggedPath).Count -gt 0) {
            Write-Host "Plugins already installed. Skipping PlugInstall."
            return
        }
    }
    Write-Host "Running :PlugInstall..."
    & nvim --headless +PlugInstall +qall
}

# Function to create offline package
function Create-Pack {
    Write-Host "Creating offline package..."
    Write-Host "Source paths:"
    Write-Host "  init.lua: $initLuaPath"
    Write-Host "  plug.vim: $plugVimPath"
    Write-Host "  plugged:  $pluggedPath"
    
    $tempDir = New-Item -ItemType Directory -Path "$env:TEMP\nvim-offline-package" -Force
    $tempNvimDir = New-Item -ItemType Directory -Path "$tempDir\nvim" -Force
    $tempNvimDataDir = New-Item -ItemType Directory -Path "$tempDir\nvim-data" -Force
    $tempAutoloadDir = New-Item -ItemType Directory -Path "$tempNvimDataDir\site\autoload" -Force

    Copy-Item $initLuaPath -Destination "$tempNvimDir\init.lua"
    Copy-Item $plugVimPath -Destination "$tempAutoloadDir\plug.vim"
    Copy-Item $pluggedPath -Destination "$tempNvimDataDir\plugged" -Recurse

    Compress-Archive -Path "$tempDir\*" -DestinationPath $defaultPackageName -Force
    Remove-Item $tempDir -Recurse -Force

    Write-Host "Offline package created successfully: $defaultPackageName"
}

# Function to unpack and install offline package
function Unpack-Package {
    param (
        [string]$PackagePath = $defaultPackageName,
        [switch]$Force
    )

    if (!(Test-Path $PackagePath)) {
        Write-Host "Error: $PackagePath not found."
        exit 1
    }
    Write-Host "Unpacking and installing offline package from $PackagePath..."
    Write-Host "Destination paths:"
    Write-Host "  init.lua: $initLuaPath"
    Write-Host "  plug.vim: $plugVimPath"
    Write-Host "  plugged:  $pluggedPath"

    if (-not $Force) {
        $confirm = Read-Host "Do you want to overwrite existing files? (y/N)"
        if ($confirm -notmatch '^[yY]$') {
            Write-Host "Operation cancelled."
            exit 0
        }
    }
    
    $tempDir = New-Item -ItemType Directory -Path "$env:TEMP\nvim-offline-package" -Force

    # Extract based on file extension
    if ($PackagePath -match '\.tar\.gz$') {
        tar -xzvf $PackagePath -C $tempDir
    }
    elseif ($PackagePath -match '\.zip$') {
        Expand-Archive -Path $PackagePath -DestinationPath $tempDir -Force
    }
    else {
        Write-Host "Error: Unsupported file format. Use .tar.gz or .zip"
        Remove-Item $tempDir -Recurse -Force
        exit 1
    }

    # Ensure destination directories exist
    New-Item -Path (Split-Path $initLuaPath) -ItemType Directory -Force | Out-Null
    New-Item -Path (Split-Path $plugVimPath) -ItemType Directory -Force | Out-Null
    New-Item -Path (Split-Path $pluggedPath) -ItemType Directory -Force | Out-Null

    # Copy files to their respective locations and verify
    Copy-Item "$tempDir\nvim\init.lua" -Destination $initLuaPath -Force
    if (Test-Path $initLuaPath) {
        Write-Host "✅ init.lua copied successfully."
    } else {
        Write-Host "❌ Failed to copy init.lua."
    }

    Copy-Item "$tempDir\nvim-data\site\autoload\plug.vim" -Destination $plugVimPath -Force
    if (Test-Path $plugVimPath) {
        Write-Host "✅ plug.vim copied successfully."
    } else {
        Write-Host "❌ Failed to copy plug.vim."
    }

    Copy-Item "$tempDir\nvim-data\plugged" -Destination (Split-Path $pluggedPath) -Recurse -Force
    if (Test-Path $pluggedPath) {
        Write-Host "✅ plugged directory copied successfully."
    } else {
        Write-Host "❌ Failed to copy plugged directory."
    }

    Remove-Item $tempDir -Recurse -Force

    Write-Host "Offline package installation complete."
}

# Main script
function Main {
    param (
        [Parameter(Mandatory=$false)]
        [ValidateSet("create-pack", "unpack")]
        [string]$Action,
        [Parameter(Mandatory=$false)]
        [string]$PackagePath,
        [switch]$Force
    )

    if (-not $Action) {
        Show-Usage
        exit 1
    }

    switch ($Action) {
        "create-pack" {
            if (!(Get-Command nvim -ErrorAction SilentlyContinue)) {
                Write-Host "Error: Neovim is not installed. Please install Neovim first."
                exit 1
            }
            if (!(Test-Path $initLuaPath)) {
                Write-Host "Error: init.lua not found at $initLuaPath"
                exit 1
            }
            Download-PlugVim
            Run-PlugInstall
            Create-Pack
        }
        "unpack" {
            Unpack-Package -PackagePath $PackagePath -Force:$Force
        }
        default {
            Show-Usage
            exit 1
        }
    }
}

# Run the main function with command-line arguments
if ($args.Count -eq 0) {
    Show-Usage
    exit 1

else {
    $params = @{
        Action = $args[0]
        PackagePath = if ($args.Count -gt 1 -and $args[1] -notmatch '^-') { $args[1] } else { $null }
        Force = $args -contains "-y"
    }
    Main @params
}
