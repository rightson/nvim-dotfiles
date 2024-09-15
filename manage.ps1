# PowerShell script for managing Neovim offline packages

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$nvimConfigDir = "$env:LOCALAPPDATA\nvim"
$plugVimPath = "$env:LOCALAPPDATA\nvim-data\site\autoload\plug.vim"
$pluggedPath = "$env:LOCALAPPDATA\nvim-data\plugged"
$packageName = "nvim-dotfile-offline.zip"

# Function to echo and execute a command
function Invoke-CommandWithEcho {
    param([string]$command)
    Write-Host "$ $command" -ForegroundColor Cyan
    Invoke-Expression $command
}

function Show-Usage {
    Write-Host "Usage: .\manage.ps1 {pack|unpack [path_to_package]|install-plug|install-plugins} [-y]"
    Write-Host "  pack                     Create an offline package of Neovim configuration"
    Write-Host "  unpack [path_to_package] Extract and install the offline package"
    Write-Host "                           If path is not specified, uses $packageName in the script directory"
    Write-Host "  install-plug             Install vim-plug"
    Write-Host "  install-plugins          Install plugins using vim-plug"
    Write-Host "  -y                       Force overwrite without prompting (for unpack)"
}

function Pack-NvimConfig {
    Write-Host "Creating offline package..."

    $tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    $nvimDir = Join-Path $tempDir "nvim"
    $nvimDataDir = Join-Path $tempDir "nvim-data"

    # Copy this repo (except the package file)
    Invoke-CommandWithEcho "New-Item -Path $nvimDir -ItemType Directory -Force | Out-Null"
    Invoke-CommandWithEcho "Get-ChildItem -Path $scriptDir -Exclude $packageName | Copy-Item -Destination $nvimDir -Recurse -Force"

    # Copy plug.vim
    Invoke-CommandWithEcho "New-Item -Path $nvimDataDir\site\autoload -ItemType Directory -Force | Out-Null"
    Invoke-CommandWithEcho "Copy-Item $plugVimPath $nvimDataDir\site\autoload\plug.vim -Force"

    # Copy plugged directory excluding .git directories
    Invoke-CommandWithEcho "New-Item -Path $nvimDataDir\plugged -ItemType Directory -Force | Out-Null"
    Invoke-CommandWithEcho "robocopy $pluggedPath $nvimDataDir\plugged /E /XD '.git' | Out-Null"

    $packagePath = Join-Path $scriptDir $packageName
    Invoke-CommandWithEcho "Compress-Archive -Path $tempDir\* -DestinationPath $packagePath -Force"
    Invoke-CommandWithEcho "Remove-Item -Recurse -Force $tempDir"
    Write-Host "Offline package created successfully: $packagePath"
}

function Install-VimPlug {
    Write-Host "Installing vim-plug..."
    $uri = 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
    New-Item -Path (Split-Path $plugVimPath) -ItemType Directory -Force | Out-Null
    Invoke-WebRequest -Uri $uri -OutFile $plugVimPath
    Write-Host "vim-plug installed successfully."
}

function Install-NvimPlugins {
    Write-Host "Installing plugins..."
    Invoke-CommandWithEcho "nvim --headless +PlugInstall +qall"
    Write-Host "Plugins installed successfully."
}

function Unpack-NvimConfig {
    param(
        [string]$packagePath = (Join-Path $scriptDir $packageName),
        [switch]$forceOverwrite
    )

    if (-not (Test-Path $packagePath)) {
        Write-Host "Error: $packagePath not found."
        exit 1
    }

    Write-Host "Unpacking and installing offline package from $packagePath..."

    if (-not $forceOverwrite) {
        $confirm = Read-Host "Do you want to overwrite existing files? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "Operation cancelled."
            exit 0
        }
    }

    $tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    Invoke-CommandWithEcho "Expand-Archive -Path '$packagePath' -DestinationPath '$tempDir'"

    # Copy nvim directory if it doesn't exist
    if (-not (Test-Path $nvimConfigDir)) {
        Write-Host "Copying Neovim configuration to $nvimConfigDir..."
        Invoke-CommandWithEcho "New-Item -Path $nvimConfigDir -ItemType Directory -Force | Out-Null"
        Invoke-CommandWithEcho "Copy-Item -Path $tempDir\nvim\* -Destination $nvimConfigDir -Recurse -Force"
    } else {
        Write-Host "$nvimConfigDir already exists. Skipping Neovim configuration copy."
    }

    # Copy plug.vim
    Invoke-CommandWithEcho "New-Item -Path (Split-Path $plugVimPath) -ItemType Directory -Force | Out-Null"
    Invoke-CommandWithEcho "Copy-Item '$tempDir\nvim-data\site\autoload\plug.vim' '$plugVimPath' -Force"

    # Copy plugged directory
    Invoke-CommandWithEcho "New-Item -Path '$pluggedPath' -ItemType Directory -Force | Out-Null"
    Invoke-CommandWithEcho "robocopy '$tempDir\nvim-data\plugged' '$pluggedPath' /E | Out-Null"

    Invoke-CommandWithEcho "Remove-Item -Recurse -Force '$tempDir'"
    Write-Host "Offline package installation complete."
}

# Main script
if ($args.Count -eq 0) {
    Show-Usage
    exit 1
}

switch ($args[0]) {
    "pack" {
        Pack-NvimConfig
    }
    "unpack" {
        $params = @{}
        $packagePath = if ($args.Count -gt 1 -and $args[1] -notmatch '^-') {
            if ([System.IO.Path]::IsPathRooted($args[1])) {
                $args[1]
            } else {
                Join-Path $PWD $args[1]
            }
        } else {
            Join-Path $scriptDir $packageName
        }
        $params['packagePath'] = $packagePath
        $params['forceOverwrite'] = $args -contains "-y"
        Unpack-NvimConfig @params
    }
    "install-plug" {
        Install-VimPlug
    }
    "install-plugins" {
        Install-NvimPlugins
    }
    default {
        Show-Usage
        exit 1
    }
}