# PowerShell script for managing Neovim offline packages

$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$packInitLuaPath = Join-Path $scriptDir "init.lua"
$unpackInitLuaPath = "$env:LOCALAPPDATA\nvim\init.lua"
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
    Write-Host "Usage: .\manage.ps1 {pack|unpack [path_to_package]} [-y] [-linux]"
    Write-Host "  pack                     Create an offline package of Neovim configuration"
    Write-Host "  unpack [path_to_package] Extract and install the offline package"
    Write-Host "                           If path is not specified, uses $packageName in the script directory"
    Write-Host "  -y                       Force overwrite without prompting"
    Write-Host "  -linux                   Create a Linux-compatible tarball (for pack operation only)"
}

function Download-PlugVim {
    if (Test-Path $plugVimPath) {
        Write-Host "plug.vim already exists. Skipping download."
    }
    else {
        Write-Host "Downloading plug.vim..."
        Invoke-CommandWithEcho "New-Item -Path (Split-Path $plugVimPath) -ItemType Directory -Force | Out-Null"
        Invoke-CommandWithEcho "Invoke-WebRequest -Uri 'https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim' -OutFile '$plugVimPath'"
    }
}

function Run-PlugCommands {
    param($initLuaPath)
    Write-Host "Running :PlugClean and :PlugInstall..."
    Invoke-CommandWithEcho "nvim --headless -u $initLuaPath +PlugClean! +PlugInstall +qall"
}

function Pack-NvimConfig {
    param([switch]$LinuxCompatible)
    
    $packageName = if ($LinuxCompatible) { "nvim-dotfile-offline-linux.zip" } else { "nvim-dotfile-offline.zip" }
    Write-Host "Creating offline package..."
    Write-Host "Source paths:"
    Write-Host "  init.lua: $packInitLuaPath"
    Write-Host "  plug.vim: $plugVimPath"
    Write-Host "  plugged:  $pluggedPath"

    if (-not (Test-Path $packInitLuaPath)) {
        Write-Host "Error: init.lua not found at $packInitLuaPath"
        exit 1
    }

    Download-PlugVim
    Run-PlugCommands $packInitLuaPath

    $tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    
    # Create directory structure
    $nvimDir = Join-Path $tempDir "nvim"
    $nvimDataDir = Join-Path $tempDir "nvim-data"
    $nvimPluggedDir = Join-Path $nvimDataDir "plugged"
    $nvimAutoloadDir = Join-Path $nvimDataDir "site/autoload"

    New-Item -Path $nvimDir, $nvimAutoloadDir -ItemType Directory -Force | Out-Null

    # Copy files
    Copy-Item $packInitLuaPath (Join-Path $nvimDir "init.lua")
    Copy-Item $plugVimPath (Join-Path $nvimAutoloadDir "plug.vim")

    # Copy plugged directory excluding .git directories
    robocopy $pluggedPath $nvimPluggedDir /E /XD '.git' | Out-Null

    $packagePath = Join-Path $scriptDir $packageName

    # Create zip archive
    if ($LinuxCompatible) {
        # Use .NET IO.Compression for Linux-compatible paths
        Add-Type -AssemblyName System.IO.Compression.FileSystem
        $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
        $includeBaseDirectory = $false

        [System.IO.Compression.ZipFile]::CreateFromDirectory($tempDir, $packagePath, $compressionLevel, $includeBaseDirectory)

        # Manually fix the directory separator for Linux compatibility
        $zip = [System.IO.Compression.ZipFile]::Open($packagePath, 'Update')
        foreach ($entry in $zip.Entries) {
            if ($entry.FullName.Contains('\')) {
                $newFullName = $entry.FullName.Replace('\', '/')
                $entry.LastWriteTime = [DateTimeOffset]::Now
            }
        }
        $zip.Dispose()
    } else {
        Compress-Archive -Path "$tempDir\*" -DestinationPath $packagePath -Force
    }

    Remove-Item -Recurse -Force $tempDir

    Write-Host "Offline package created successfully: $packagePath"
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
    Write-Host "Destination paths:"
    Write-Host "  init.lua: $unpackInitLuaPath"
    Write-Host "  plug.vim: $plugVimPath"
    Write-Host "  plugged:  $pluggedPath"

    if (-not $forceOverwrite) {
        $confirm = Read-Host "Do you want to overwrite existing files? (y/N)"
        if ($confirm -ne "y" -and $confirm -ne "Y") {
            Write-Host "Operation cancelled."
            exit 0
        }
    }

    $tempDir = Join-Path $env:TEMP ([System.Guid]::NewGuid().ToString())
    Invoke-CommandWithEcho "Expand-Archive -Path '$packagePath' -DestinationPath '$tempDir'"

    Invoke-CommandWithEcho "New-Item -Path (Split-Path $unpackInitLuaPath) -ItemType Directory -Force | Out-Null"
    Invoke-CommandWithEcho "New-Item -Path (Split-Path $plugVimPath) -ItemType Directory -Force | Out-Null"
    Invoke-CommandWithEcho "New-Item -Path '$pluggedPath' -ItemType Directory -Force | Out-Null"

    Invoke-CommandWithEcho "Copy-Item '$tempDir\nvim\init.lua' '$unpackInitLuaPath' -Force"
    Invoke-CommandWithEcho "Copy-Item '$tempDir\nvim-data\site\autoload\plug.vim' '$plugVimPath' -Force"
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
        if (-not (Get-Command nvim -ErrorAction SilentlyContinue)) {
            Write-Host "Error: Neovim is not installed or not in PATH. Please install Neovim first."
            exit 1
        }
        $linuxOption = $args -contains "-linux"
        Pack-NvimConfig -LinuxCompatible:$linuxOption
    }
    "unpack" {
        $packagePath = if ($args.Count -gt 1 -and $args[1] -ne "-y") { 
            if ([System.IO.Path]::IsPathRooted($args[1])) {
                $args[1]
            } else {
                Join-Path $PWD $args[1]
            }
        } else { 
            Join-Path $scriptDir $packageName 
        }
        $forceOverwrite = $args -contains "-y"
        Unpack-NvimConfig -packagePath $packagePath -forceOverwrite:$forceOverwrite
    }
    default {
        Show-Usage
        exit 1
    }
}
