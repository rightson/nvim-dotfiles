-- Neovim Configuration in Lua

-- Plugin Management
local function setup_plugins()
    local Plug = vim.fn['plug#']
    vim.call('plug#begin')

    Plug('neovim/nvim-lspconfig')
    Plug('hrsh7th/nvim-cmp')
    Plug('hrsh7th/cmp-path')
    Plug('windwp/nvim-autopairs')
    Plug('phaazon/hop.nvim')
    Plug('nvim-lua/plenary.nvim')
    Plug('nvim-telescope/telescope.nvim')
    Plug('preservim/nerdtree')
    Plug('preservim/tagbar')
    Plug('nyngwang/NeoZoom.lua')
    Plug('editorconfig/editorconfig-vim')
    Plug('alvan/vim-closetag')
    Plug('airblade/vim-gitgutter')
    Plug('mhinz/vim-startify')
    Plug('tpope/vim-surround')
    Plug('NLKNguyen/papercolor-theme')
    Plug('tell-k/vim-autopep8')

    vim.call('plug#end')
end

-- General Settings
local function setup_general_settings()
    vim.o.shell = '/bin/bash'
    vim.o.syntax = 'on'
    vim.o.history = 512
    vim.o.hidden = true
    vim.o.timeoutlen = 250
    vim.o.showcmd = true
    vim.o.wildmode = 'longest:list,full'
    vim.o.autoread = true
    vim.o.autowrite = true
    vim.o.clipboard = 'unnamedplus'
    vim.o.pastetoggle = '<F7>'
    vim.o.mouse = 'a'
    vim.o.vb = true
    vim.o.t_vb = ''
    vim.o.ruler = true
    vim.o.wrap = false
    vim.o.linebreak = true
    vim.o.relativenumber = true
    vim.o.foldenable = true
    vim.o.foldmethod = 'manual'
    vim.o.foldcolumn = '0'
    vim.o.foldlevel = 99
    vim.o.foldopen = 'block,hor,mark,percent,quickfix,tag'
    vim.o.cindent = true
    vim.o.autoindent = true
    vim.o.smartindent = true
    vim.o.expandtab = true
    vim.o.tabstop = 4
    vim.o.shiftwidth = 4
    vim.o.softtabstop = 4
    vim.o.incsearch = true
    vim.o.hlsearch = true
    vim.o.ignorecase = false
    vim.o.backspace = 'indent,eol,start'
    vim.o.laststatus = 2

    -- GUI specific settings
    if vim.fn.has('gui_running') == 1 then
        vim.o.clipboard = 'unnamedplus'
        vim.o.guioptions = vim.o.guioptions:gsub('T', '')
        vim.o.guioptions = vim.o.guioptions:gsub('r', '')
        vim.o.guioptions = vim.o.guioptions:gsub('L', '')
        vim.o.linespace = 2
        vim.o.guitablabel = '%N: %M%t'
        vim.o.errorbells = false
        vim.o.visualbell = true
        vim.o.t_vb = ''
    end
end

-- Key Mappings
local function setup_key_mappings()
    local function map(mode, lhs, rhs, opts)
        local options = {noremap = true, silent = true}
        if opts then options = vim.tbl_extend('force', options, opts) end
        vim.api.nvim_set_keymap(mode, lhs, rhs, options)
    end

    -- Buffer navigation
    map('n', 'T', ':bnext<CR>')
    map('n', 'F', ':buffers<CR>')

    -- Tab navigation
    map('n', '<C-j>', 'gt<CR>')
    map('n', '<C-k>', 'gT<CR>')

    -- Function keys
    map('n', '<F3>', ':cs find s <C-R>=expand("<cword>")<CR><CR>')
    map('n', '<F4>', ':qa<CR>')
    map('n', '<F5>', ':silent! cs kill 0<CR> :mapclear<CR> :source ~/.config/nvim/init.lua<CR> cs add cscope.out<CR>')
    map('n', '<F6>', ':NERDTreeToggle<CR>')
    map('n', '<F8>', ':TagbarToggle<CR>')
    map('n', '<F10>', '<C-w>|<C-w>_')
    map('n', '<S-F10>', '<C-w>=')
    map('n', '<F12>', ':lua ToggleLineNumber()<CR>')

    -- Search and replace
    map('n', '<C-G>', '<Esc>:echo expand("%:p")<CR>')

    -- Grep
    map('n', 'GG', ':grep "\\<<C-R><C-W>\\>" * -rn --color<CR>:copen 10<CR>')
    map('n', 'GC', ':cclose<CR>')
end

-- Plugin Configurations
local function setup_plugin_configs()
    -- nvim-lspconfig
    local lspconfig = require('lspconfig')
    lspconfig.pyright.setup{}
    lspconfig.tsserver.setup{}
    lspconfig.jsonls.setup{}
    lspconfig.html.setup{}

    -- nvim-cmp
    require('cmp').setup({
        sources = {
            { name = 'path' }
        }
    })

    -- nvim-autopairs
    require('nvim-autopairs').setup{}

    -- hop.nvim
    require('hop').setup{}

    -- telescope.nvim
    local actions = require('telescope.actions')
    local action_state = require('telescope.actions.state')
    require('telescope').setup{
        defaults = {
            mappings = {
                i = {
                    ["<C-u>"] = function(prompt_bufnr)
                        local picker = action_state.get_current_picker(prompt_bufnr)
                        local prompt = picker:get_prompt()
                        if prompt == "" then
                            picker:set_prompt("")
                        end
                    end
                }
            }
        }
    }

    -- Neo-Zoom
    require('neo-zoom').setup {
        winopts = {
            offset = {
                width = 120,
                height = 80,
                border = 'double'
            }
        }
    }
end

-- Autocommands
local function setup_autocommands()
    vim.cmd([[
        augroup FileTypeSpecific
            autocmd!
            autocmd BufRead,BufNewFile jquery.*.js set ft=javascript syntax=jquery
            autocmd BufRead,BufNewFile *.tss set ft=css
            autocmd BufRead,BufNewFile {*.md,*.mkd,*.markdown} set ft=markdown
            autocmd BufRead,BufNewFile {COMMIT_EDITMSG} set ft=gitcommit
            autocmd BufRead,BufNewFile *.p4template set syntax=p4
            autocmd FileType py,html,xml,htm,xsl setlocal expandtab tabstop=4 shiftwidth=4 softtabstop=4
            autocmd FileType c,cpp,c++,h,hpp setlocal cindent autoindent smartindent expandtab
            autocmd FileType GNUMakefile,Makefile,makefile,make,mk setlocal noexpandtab
            autocmd FileType txt,tex,md setlocal wrap
            autocmd FileType txt,tex,md noremap <silent> k gk
            autocmd FileType txt,tex,md noremap <silent> j gj
            autocmd FileType txt,tex,md noremap <silent> $ g$
        augroup END

        augroup Miscellaneous
            autocmd!
            autocmd BufWritePre * lua StripTrailingWhitespace()
            autocmd BufReadPost * lua RestoreLastCursorPosition()
            autocmd FilterWritePre * if &diff | setlocal wrap< | endif
        augroup END
    ]])
end

-- Custom Functions
local function setup_custom_functions()
    _G.ToggleLineNumber = function()
        if vim.wo.number then
            vim.wo.number = false
        else
            vim.wo.number = true
        end
    end

    _G.StripTrailingWhitespace = function()
        local current_view = vim.fn.winsaveview()
        vim.cmd([[%s/\s\+$//e]])
        vim.fn.winrestview(current_view)
    end

    _G.RestoreLastCursorPosition = function()
        local last_pos = vim.fn.line("'\"")
        if last_pos > 0 and last_pos <= vim.fn.line("$") then
            vim.cmd('normal! g`"')
        end
    end
end

-- Cursor Position Restoration
local function setup_cursor_position_restoration()
    vim.api.nvim_create_autocmd({"BufReadPost"}, {
        pattern = {"*"},
        callback = function()
            local mark = vim.api.nvim_buf_get_mark(0, '"')
            local lcount = vim.api.nvim_buf_line_count(0)
            if mark[1] > 0 and mark[1] <= lcount then
                pcall(vim.api.nvim_win_set_cursor, 0, mark)
            end
        end,
    })
end


-- Main Setup Function
local function setup()
    setup_plugins()
    setup_general_settings()
    setup_key_mappings()
    setup_plugin_configs()
    setup_autocommands()
    setup_custom_functions()
    setup_cursor_position_restoration()
end

-- Run the setup
setup()
