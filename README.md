# nvim-dotfiles

Welcome to nvim-dotfiles, a minimalist Neovim configuration for those who appreciate simplicity and efficiency. While there are many Neovim configurations out there, this one focuses on providing a clean, lightweight setup with carefully chosen settings and plugins.

## Features

- Minimalist approach with essential plugins
- Lua-based configuration for improved performance
- LSP support for Python, TypeScript, JSON, and HTML
- Useful keybindings for improved productivity
- Autocommands for various file types
- Custom functions for common tasks

## Prerequisites

- Neovim (>= 0.5.0)
- Git
- Node.js and npm (for LSP servers)

## Installation

1. Back up your existing Neovim configuration:
   ```
   mv ~/.config/nvim ~/.config/nvim.bak
   ```

2. Clone this repository:
   ```
   git clone https://github.com/rightson/nvim-dotfiles.git ~/.config/nvim
   ```

3. Install vim-plug:
   ```
   sh -c 'curl -fLo "${XDG_DATA_HOME:-$HOME/.local/share}"/nvim/site/autoload/plug.vim --create-dirs \
          https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim'
   ```

4. Open Neovim and install plugins:
   ```
   nvim +PlugInstall +qall
   ```

5. Install LSP servers:
   ```
   npm install -g pyright typescript typescript-language-server vscode-langservers-extracted
   ```

## Configuration

The main configuration file is `~/.config/nvim/init.lua`. You can modify this file to customize your Neovim experience further.

## Key Mappings

Here are some of the key mappings included in this configuration:

### General
- `<C-j>`: Next tab
- `<C-k>`: Previous tab
- `<C-g>`: Show current file's absolute path
- `<F4>`: Quit all
- `<F5>`: Reload configuration
- `GG`: Grep current word

### LSP
- `<F12>` or `gd`: Go to definition
- `K`: Hover information
- `gi`: Go to implementation
- `gr`: Find references
- `gf`: Format document

### hop.nvim
- `<leader>w`: Hop word
- `<leader>l`: Hop line
- `<leader>c`: Hop char1
- `<leader>cc`: Hop char2

### Telescope
- `<C-p>` or `<leader>f`: Find files
- `<leader><header>g`: Live grep
- `<leader><header>b`: List buffers
- `<leader><header>h`: Help tags

### Other Plugins
- `<F6>` or `<leader>n`: Toggle NERDTree
- `<F8>` or `<leader>t`: Toggle Tagbar
- `<leader>z`: Toggle NeoZoom

## Plugins

This configuration includes several carefully selected plugins:

- nvim-lspconfig: For LSP support
- nvim-cmp: For autocompletion
- nvim-autopairs: For automatic bracket pairing
- hop.nvim: For easy motions
- telescope.nvim: For fuzzy finding
- NERDTree: For file system exploration
- Tagbar: For code structure overview
- NeoZoom: For zooming into windows

And several others for various enhancements. Check the `init.lua` file for a complete list.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the [MIT License](LICENSE).

## Acknowledgements

Thanks to the Neovim community and the authors of the plugins used in this configuration.

Enjoy your minimal Neovim setup!
