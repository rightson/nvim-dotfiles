#!/bin/bash

set -e

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
NVIM_CONFIG_DIR="$HOME/.config/nvim"
PLUG_VIM_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/site/autoload/plug.vim"
PLUGGED_PATH="${XDG_DATA_HOME:-$HOME/.local/share}/nvim/plugged"
DEFAULT_PACKAGE_NAME="nvim-dotfile-offline.tar.gz"

# Function to echo and execute a command
execho() {
    echo "\$ $@"
    "$@"
}

# Function to show usage
show_usage() {
    echo "Usage: $0 {pack|unpack [path_to_package]|install-plug|install-plugins|install-lsp-servers} [-y]"
    echo "  pack                     Create an offline package of Neovim configuration"
    echo "  unpack [path_to_package] Extract and install the offline package"
    echo "                           If path is not specified, uses $DEFAULT_PACKAGE_NAME in the script directory"
    echo "  install                  Install vim-plug, plugins, and lsp servers"
    echo "  install-plug             Install vim-plug"
    echo "  install-plugins          Install plugins using vim-plug"
    echo "  install-lsp-servers      Install lsp servers using npm"
    echo "  -y                       Force overwrite without prompting (for unpack)"
}

# Function to create offline package
pack() {
    echo "Creating offline package..."

    local temp_dir=$(mktemp -d)
    local nvim_dir="$temp_dir/nvim"
    local nvim_data_dir="$temp_dir/nvim-data"

    # Copy this repo (except the package file)
    execho rsync -a --exclude="$DEFAULT_PACKAGE_NAME" "$SCRIPT_DIR/" "$nvim_dir/"

    # Copy plug.vim
    execho mkdir -p "$nvim_data_dir/site/autoload"
    execho cp "$PLUG_VIM_PATH" "$nvim_data_dir/site/autoload/"

    # Copy plugged directory excluding .git directories
    execho mkdir -p "$nvim_data_dir/plugged"
    execho rsync -a --exclude='.git' "$PLUGGED_PATH/" "$nvim_data_dir/plugged/"

    local package_path="$SCRIPT_DIR/$DEFAULT_PACKAGE_NAME"
    execho tar -czf "$package_path" -C "$temp_dir" .
    execho rm -rf "$temp_dir"
    echo "Offline package created successfully: $package_path"
}

# Function to install vim-plug
install_plug() {
    echo "Installing vim-plug..."
    curl -fLo "${PLUG_VIM_PATH}" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    echo "vim-plug installed successfully."
}

# Function to install plugins
install_plugins() {
    echo "Installing plugins..."
    nvim --headless +PlugInstall +qall
    echo "Plugins installed successfully."
}

# Function to install lsp servers
install_lsp_servers() {
    echo "Installing lsp servers..."
    npm install -g pyright typescript typescript-language-server vscode-langservers-extracted
    echo "lsp servers installed successfully."
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

    if [ "$force_overwrite" = false ]; then
        read -p "Do you want to overwrite existing files? (y/N) " confirm
        if [[ $confirm != [yY] ]]; then
            echo "Operation cancelled."
            exit 0
        fi
    fi

    local temp_dir=$(mktemp -d)
    execho tar -xzf "$package_path" -C "$temp_dir"

    # Copy nvim directory if it doesn't exist
    if [ ! -d "$NVIM_CONFIG_DIR" ]; then
        echo "Copying Neovim configuration to $NVIM_CONFIG_DIR..."
        execho mkdir -p "$NVIM_CONFIG_DIR"
        execho cp -R "$temp_dir/nvim/." "$NVIM_CONFIG_DIR/"
    else
        echo "$NVIM_CONFIG_DIR already exists. Skipping Neovim configuration copy."
    fi

    # Copy plug.vim
    execho mkdir -p "$(dirname "$PLUG_VIM_PATH")"
    execho cp "$temp_dir/nvim-data/site/autoload/plug.vim" "$PLUG_VIM_PATH"

    # Copy plugged directory
    execho mkdir -p "$PLUGGED_PATH"
    execho rsync -a "$temp_dir/nvim-data/plugged/" "$PLUGGED_PATH/"

    execho rm -rf "$temp_dir"
    echo "Offline package installation complete."
}

# Main script
if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    pack)
        pack
        ;;
    unpack)
        shift
        unpack "$@"
        ;;
    install)
        install_plug
        install_plugins
        install_lsp_servers
        ;;
    install-plug)
        install_plug
        ;;
    install-plugins)
        install_plugins
        ;;
    install-lsp-servers)
        install_lsp_servers
        ;;
    *)
        show_usage
        exit 1
        ;;
esac
