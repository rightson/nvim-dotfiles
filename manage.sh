#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
PACK_INIT_LUA_PATH="$SCRIPT_DIR/init.lua"
UNPACK_INIT_LUA_PATH="$HOME/.config/nvim/init.lua"
PLUG_VIM_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
PLUGGED_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/plugged"
DEFAULT_PACKAGE_NAME="nvim-dotfile-offline.tar.gz"

# Function to show usage
show_usage() {
    echo "Usage: $0 {pack|unpack [path_to_package]} [-y]"
    echo "  pack                     Create an offline package of Neovim configuration"
    echo "  unpack [path_to_package] Extract and install the offline package"
    echo "                           If path is not specified, uses $DEFAULT_PACKAGE_NAME in the script directory"
    echo "  -y                       Force overwrite without prompting"
}

# Function to download plug.vim
download_plug_vim() {
    if [ -f "$PLUG_VIM_PATH" ]; then
        echo "plug.vim already exists. Skipping download."
    else
        echo "Downloading plug.vim..."
        curl -fLo "$PLUG_VIM_PATH" --create-dirs \
            https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    fi
}

# Function to run PlugClean and PlugInstall
run_plug_commands() {
    local init_lua_path="$1"
    echo "Running :PlugClean and :PlugInstall..."
    nvim --headless -u "$init_lua_path" +PlugClean! +PlugInstall +qall
}

# Function to create offline package
pack() {
    echo "Creating offline package..."
    echo "Source paths:"
    echo "  init.lua: $PACK_INIT_LUA_PATH"
    echo "  plug.vim: $PLUG_VIM_PATH"
    echo "  plugged:  $PLUGGED_PATH"

    if [ ! -f "$PACK_INIT_LUA_PATH" ]; then
        echo "Error: init.lua not found at $PACK_INIT_LUA_PATH"
        exit 1
    fi

    # Ensure plug.vim is downloaded
    download_plug_vim

    # Run PlugClean and PlugInstall with the local init.lua
    run_plug_commands "$PACK_INIT_LUA_PATH"

    local temp_dir=$(mktemp -d)
    mkdir -p "$temp_dir/nvim" "$temp_dir/nvim-data/site/autoload"
    cp "$PACK_INIT_LUA_PATH" "$temp_dir/nvim/"
    cp "$PLUG_VIM_PATH" "$temp_dir/nvim-data/site/autoload/"
    
    # Copy plugged directory excluding .git directories
    mkdir -p "$temp_dir/nvim-data/plugged"
    rsync -a --exclude='.git' "$PLUGGED_PATH/" "$temp_dir/nvim-data/plugged/"

    local package_path="$SCRIPT_DIR/$DEFAULT_PACKAGE_NAME"
    tar -czf "$package_path" -C "$temp_dir" .
    rm -rf "$temp_dir"
    echo "Offline package created successfully: $package_path"
}

# Function to unpack and install offline package
unpack() {
    local package_path="${1:-"$SCRIPT_DIR/$DEFAULT_PACKAGE_NAME"}"
    local force_overwrite=false
    if [ "$2" == "-y" ]; then
        force_overwrite=true
    fi

    if [ ! -f "$package_path" ]; then
        echo "Error: $package_path not found."
        exit 1
    fi
    echo "Unpacking and installing offline package from $package_path..."
    echo "Destination paths:"
    echo "  init.lua: $UNPACK_INIT_LUA_PATH"
    echo "  plug.vim: $PLUG_VIM_PATH"
    echo "  plugged:  $PLUGGED_PATH"

    if [ "$force_overwrite" = false ]; then
        read -p "Do you want to overwrite existing files? (y/N) " confirm
        if [[ $confirm != [yY] ]]; then
            echo "Operation cancelled."
            exit 0
        fi
    fi

    local temp_dir=$(mktemp -d)

    # Extract based on file extension
    case "$package_path" in
        *.tar.gz)
            tar -xzf "$package_path" -C "$temp_dir"
            ;;
        *.zip)
            unzip -q "$package_path" -d "$temp_dir"
            ;;
        *)
            echo "Error: Unsupported file format. Use .tar.gz or .zip"
            rm -rf "$temp_dir"
            exit 1
            ;;
    esac

    # Copy files to their respective locations
    mkdir -p "$(dirname "$UNPACK_INIT_LUA_PATH")"
    mkdir -p "$(dirname "$PLUG_VIM_PATH")"
    mkdir -p "$PLUGGED_PATH"

    cp "$temp_dir/nvim/init.lua" "$UNPACK_INIT_LUA_PATH"
    cp "$temp_dir/nvim-data/site/autoload/plug.vim" "$PLUG_VIM_PATH"
    rsync -a "$temp_dir/nvim-data/plugged/" "$PLUGGED_PATH/"

    rm -rf "$temp_dir"
    echo "Offline package installation complete."

    # Run PlugClean and PlugInstall with the newly unpacked init.lua
    run_plug_commands "$UNPACK_INIT_LUA_PATH"
}

# Main script
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    pack)
        if ! command -v nvim &> /dev/null; then
            echo "Error: Neovim is not installed. Please install Neovim first."
            exit 1
        fi
        pack
        ;;
    unpack)
        if [ $# -gt 1 ] && [ "$2" != "-y" ]; then
            if [[ "$2" = /* ]]; then
                package_path="$2"
            else
                package_path="$PWD/$2"
            fi
        else
            package_path="$SCRIPT_DIR/$DEFAULT_PACKAGE_NAME"
        fi
        unpack "$package_path" "${3:-}"
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
