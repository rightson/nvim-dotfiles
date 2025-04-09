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
    Write-Host "Usage: .\manage.ps1 {pack|unpack [path_to_package]|install-plug|install-plugins|install-lsp-servers} [-y]"
    Write-Host "  pack                     Create an offline package of Neovim configuration"
    Write-Host "  unpack [path_to_package] Extract and install the offline package"
    Write-Host "                           If path is not specified, uses $packageName in the script directory"
    Write-Host "  install                  Install vim-plug, plugins, and lsp servers"
    Write-Host "  install-plug             Install vim-plug"
    Write-Host "  install-plugins          Install plugins using vim-plug"
    Write-Host "  install-lsp-servers      Install LSP servers using npm"
    Write-Host "  -y                       Force overwrite without prompting (for unpack)"
}

# Function to install vim-plug
function Install-VimPlug {
    Write-Host "Installing vim-plug..."
    
    # Create the necessary directories if they don't exist
    if (-not (Test-Path $plugVimPath)) {
        New-Item -ItemType Directory -Path (Split-Path $plugVimPath -Parent) -Force
    }

    # Download vim-plug
    Invoke-WebRequest -Uri "https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim" -OutFile $plugVimPath

    Write-Host "vim-plug installed successfully."
}

# Function to install Neovim plugins using vim-plug
function Install-NvimPlugins {
    Write-Host "Installing Neovim plugins..."
    
    # Ensure Neovim is installed
    if (!(Get-Command nvim -ErrorAction SilentlyContinue)) {
        Write-Host "Error: Neovim is not installed. Please install Neovim before running this command." -ForegroundColor Red
        exit 1
    }

    # Install plugins using vim-plug
    Invoke-CommandWithEcho "nvim +PlugInstall +qall"

    Write-Host "Neovim plugins installed successfully."
}

# Function to pack Neovim configuration
function Pack-NvimConfig {
    Write-Host "Packing Neovim configuration..."
    
    # Create a zip package of the Neovim configuration
    Compress-Archive -Path $nvimConfigDir -DestinationPath (Join-Path $scriptDir $packageName)

    Write-Host "Neovim configuration packed successfully."
}

# Function to unpack Neovim configuration
function Unpack-NvimConfig {
    param(
        [string]$packagePath,
        [bool]$forceOverwrite = $false
    )

    Write-Host "Unpacking Neovim configuration from $packagePath..."

    # Check if the destination directory exists
    if (Test-Path $nvimConfigDir -and !$forceOverwrite) {
        Write-Host "Error: Destination directory already exists. Use -y to force overwrite." -ForegroundColor Red
        exit 1
    }

    # Extract the zip package
    Expand-Archive -Path $packagePath -DestinationPath $nvimConfigDir -Force

    Write-Host "Neovim configuration unpacked successfully."
}

function Install-LspServers {
    Write-Host "Installing LSP servers..."
    
    # Check if npm is installed
    if (!(Get-Command npm -ErrorAction SilentlyContinue)) {
        Write-Host "Error: npm is not installed. Please install Node.js and npm before running this command." -ForegroundColor Red
        exit 1
    }

    $servers = @("pyright", "typescript", "typescript-language-server", "vscode-langservers-extracted")
    
    foreach ($server in $servers) {
        Write-Host "Installing $server..."
        Invoke-CommandWithEcho "npm install -g $server"
    }

    Write-Host "LSP servers installed successfully."
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
    "install" {
        Install-VimPlug
        Install-NvimPlugins
        Install-LspServers
    }
    "install-plug" {
        Install-VimPlug
    }
    "install-plugins" {
        Install-NvimPlugins
    }
    "install-lsp-servers" {
        Install-LspServers
    }
    default {
        Show-Usage
        exit 1
    }
}
