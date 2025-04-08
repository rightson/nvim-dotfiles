-- Neovim Configuration in Lua

-- Plugin Management
local function setup_plugins()
    local Plug = vim.fn['plug#']
    vim.call('plug#begin')

    Plug('neovim/nvim-lspconfig')
    Plug('hrsh7th/nvim-cmp')
    Plug('hrsh7th/cmp-path')
    Plug('windwp/nvim-autopairs')
    Plug('smoka7/hop.nvim')
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
    Plug('lervag/vimtex')

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
    vim.o.paste = true
    --- vim.o.pastetoggle = '<F7>'
    vim.o.mouse = 'a'
    --- vim.o.vb = true
    --- vim.o.t_vb = ''
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
    vim.env.FZF_DEFAULT_COMMAND = [[find . \( -name node_modules -o -name .git \) -prune -o -print]]

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

    -- Tab navigation
    map('n', '<C-j>', 'gt<CR>')
    map('n', '<C-k>', 'gT<CR>')

    -- Function keys
    map('n', '<F4>', ':qa!<CR>')
    map('n', '<F5>', ':luafile ~/.config/nvim/init.lua<CR>')

    -- Search and replace
    map('n', '<C-G>', '<Esc>:echo expand("%:p")<CR>')

    -- Grep
    map('n', 'GG', ':grep "\\<<C-R><C-W>\\>" * -rn --color<CR>:copen<CR>')

    -- LSP key mappings
    map('n', '<F12>', '<cmd>lua vim.lsp.buf.definition()<CR>')
    map('n', '<leader>gd', '<cmd>lua vim.lsp.buf.definition()<CR>')
    map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>')
    map('n', '<leader>gi', '<cmd>lua vim.lsp.buf.implementation()<CR>')
    map('n', '<leader>gr', '<cmd>lua vim.lsp.buf.references()<CR>')
    map('n', '<leader>gf', '<cmd>lua vim.lsp.buf.format()<CR>')

    -- hop.nvim key mappings
    map('n', '<leader>w', ':HopWord<CR>')
    map('n', '<leader>l', ':HopLine<CR>')
    map('n', '<leader>c', ':HopChar1<CR>')
    map('n', '<leader>cc', ':HopChar2<CR>')

    -- Telescope key mappings
    map('n', '<C-p>', '<cmd>Telescope find_files<CR>')
    map('n', '<leader><leader>f', '<cmd>Telescope find_files<CR>')
    map('n', '<leader><leader>g', '<cmd>Telescope live_grep<CR>')
    map('n', '<leader><leader>b', '<cmd>Telescope buffers<CR>')
    map('n', '<leader><leader>h', '<cmd>Telescope help_tags<CR>')

    -- NERDTree key mapping
    map('n', '<leader>n', ':NERDTreeFind<CR> :wincmd p<CR>')
    map('n', '<leader>o', ':NERDTreeClose<CR>')

    -- TagBar key mapping
    map('n', '<leader>t', ':TagbarToggle<CR>')

    -- Neo-Zoom key mapping
    map('n', '<leader>z', ':NeoZoomToggle<CR>')

    -- vimtex
    vim.api.nvim_create_autocmd('FileType', {
        pattern = 'tex',
        callback = function()
            if vim.loop.os_uname().sysname == "Darwin" then
                map('n', '<leader>v', ':VimtexView<CR>:!osascript -e \'tell application "Skim" to activate\'<CR>')
            else
                map('n', '<leader>v', ':VimtexView<CR>')
            end
            map('n', '<leader>t', ':VimtexTocToggle<CR> ')
        end
    })
end

-- Plugin Configurations
local function setup_plugin_configs()
    -- nvim-lspconfig
    local lspconfig = require('lspconfig')
    lspconfig.pyright.setup{}
    lspconfig.ts_ls.setup{}
    lspconfig.jsonls.setup{}
    lspconfig.html.setup{}

    -- nvim-cmp
    local cmp = require('cmp')
    cmp.setup({
        sources = {
            { name = 'path' }
        },
        mapping = {
            ['<Tab>'] = cmp.mapping.select_next_item(),
            ['<S-Tab>'] = cmp.mapping.select_prev_item(),
            ['<CR>'] = cmp.mapping.confirm({ select = true }),
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

    -- NERDTree Configuration
    -- vim.cmd([[
    --    autocmd VimEnter * NERDTreeFind
    --    autocmd VimEnter * wincmd p
    -- ]])

    -- vimtex
    vim.g.vimtex_view_method = 'skim'
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

-- Load Local Lua Configuration
local function load_local_config()
    local local_config_path = vim.fn.stdpath('config') .. '/lua/local.lua'
    local file = io.open(local_config_path, "r")
    if file then
        io.close(file)
        vim.defer_fn(function()
            vim.api.nvim_command("colorscheme PaperColor")
            -- Load the local.lua file
            dofile(local_config_path)
        end, 1)
    end
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
    vim.defer_fn(load_local_config, 0)
end

-- Run the setup
setup()
