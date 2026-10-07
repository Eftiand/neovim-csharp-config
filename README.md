# Meon - Neovim Configuration for C# Development

A fully-featured Neovim configuration optimized for **C# / .NET development on macOS**. Includes Roslyn LSP, debugging with netcoredbg, unit testing with Neotest, and 50+ carefully configured plugins.

## Features

- **Roslyn Language Server** - Modern C# LSP with intelligent code analysis
- **Integrated Debugging** - netcoredbg with DAP UI, breakpoints, watches, and REPL
- **Unit Testing** - Neotest integration with test running and debugging
- **.NET Build Integration** - Direct `dotnet build` with quickfix error navigation
- **VS Code Compatibility** - Reads `launch.json` and `settings.json` configurations
- **macOS ARM64 Optimized** - Native Apple Silicon debugger and clipboard support

## Requirements

- Neovim 0.9+
- .NET SDK 8.0+
- macOS (ARM64/Apple Silicon)
- Git
- [fzf](https://github.com/junegunn/fzf) (for fuzzy finding)
- `curl` and [tree-sitter CLI](https://github.com/tree-sitter/tree-sitter) (for rest.nvim's luarocks dependencies)
- A [Nerd Font](https://www.nerdfonts.com/) (for icons)

## Installation

```bash
# Backup existing config
mv ~/.config/nvim ~/.config/nvim.bak

# Clone this repository
git clone https://github.com/Eftiand/neovim-csharp-config.git ~/.config/nvim

# Open Neovim - plugins will install automatically
nvim
```

## Structure

```
~/.config/nvim/
├── init.lua                 # Entry point
├── lazy-lock.json          # Plugin version locks
└── lua/meon/
    ├── core/
    │   ├── options.lua     # Editor settings
    │   └── keymaps.lua     # Key bindings
    ├── lazy.lua            # Plugin manager setup
    ├── plugins/
    │   ├── lsp/
    │   │   ├── roslyn.lua  # C# language server
    │   │   ├── lspconfig.lua
    │   │   └── mason.lua
    │   ├── nvim-dap.lua    # Debug adapter
    │   ├── nvim-dap-ui.lua # Debug UI
    │   ├── neotest.lua     # Test runner
    │   └── [...]           # 50+ plugin configs
    └── util/
        └── json5.lua       # VS Code launch.json parser
```

## Key Bindings

**Leader key**: `<Space>`

### LSP Navigation

| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gD` | Go to declaration |
| `gi` | Go to implementations |
| `gr` | Go to references |
| `gt` | Go to type definition |
| `K` | Hover documentation |
| `<leader>ca` | Code actions |
| `<leader>rn` | Rename symbol |
| `<leader>D` | Document diagnostics |
| `<leader>d` | Line diagnostics |

### Building & Debugging

| Key | Action |
|-----|--------|
| `<leader>bp` | Build project (`dotnet build`) |
| `<F5>` | Continue / Start debugging |
| `<F9>` | Toggle breakpoint |
| `<F10>` | Step over |
| `<F11>` | Step into |
| `<F8>` | Step out |
| `<leader>du` | Toggle DAP UI |
| `<leader>dw` | Watch variable |
| `<leader>dr` | Open REPL |

### Testing (Neotest)

| Key | Action |
|-----|--------|
| `<leader>tr` | Run nearest test |
| `<leader>tf` | Run file tests |
| `<leader>td` | Debug nearest test |
| `<leader>ts` | Toggle test summary |
| `<leader>to` | Open test output |
| `<leader>tx` | Stop tests |

### File Navigation

| Key | Action |
|-----|--------|
| `<leader>ff` | Find files |
| `<leader>fa` | Find all files (including hidden) |
| `<leader>fr` | Recent files |
| `<leader>fs` | Live grep |
| `<leader>fc` | Grep word under cursor |
| `<leader>ft` | Find TODOs |

### Harpoon (Quick File Access)

| Key | Action |
|-----|--------|
| `<leader>ha` | Add file to harpoon |
| `<leader>hh` | Open harpoon menu |
| `<leader>1-4` | Jump to harpooned file 1-4 |

### Window Management

| Key | Action |
|-----|--------|
| `sh` | Split vertical |
| `sv` | Split horizontal |
| `se` | Equal split sizes |
| `sx` | Close split |
| `<leader>sm` | Maximize/restore window |

### HTTP Client (`.http` files)

| Key | Action |
|-----|--------|
| `<leader>Rr` | Run request under cursor |
| `<leader>Rf` | Pick a named request (`# @name foo`) and run it |
| `<leader>Rl` | Re-run last request |
| `<leader>Ro` | Open response pane |
| `<leader>Rc` | Yank request as a `curl` command |

Inside the response pane, `H`/`L` cycle between Response / Headers / Cookies / Statistics.
`:Rest env select`, `:Rest cookies` and `:Rest logs` are available as commands.

### Other

| Key | Action |
|-----|--------|
| `jk` | Exit insert mode |
| `<leader>nh` | Clear search highlights |
| `<leader>rr` | Reload config |
| `T` | Toggle floating terminal |
| `:Ofinder` | Open current file in Finder |

## C# Development Setup

### Roslyn LSP

The configuration uses [roslyn.nvim](https://github.com/seblyng/roslyn.nvim) for C# language support. It automatically activates for `.cs` files with optimized settings:

- Background analysis scoped to open files (better performance)
- Inlay hints disabled for cleaner code view
- Full diagnostics from analyzers and compiler

### Debugging

Debugging uses [netcoredbg](https://github.com/Samsung/netcoredbg) compiled for macOS ARM64. The debugger is bundled via [netcoredbg-macOS-arm64.nvim](https://github.com/Cliffback/netcoredbg-macOS-arm64.nvim).

**To debug a project:**

1. Create a `.vscode/launch.json` in your project (VS Code format supported)
2. Set breakpoints with `<F9>`
3. Start debugging with `<F5>`

Example `launch.json`:
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "name": ".NET Core Launch (console)",
      "type": "coreclr",
      "request": "launch",
      "program": "${workspaceFolder}/bin/Debug/net8.0/YourApp.dll",
      "args": [],
      "cwd": "${workspaceFolder}",
      "stopAtEntry": false
    }
  ]
}
```

### Building

Press `<leader>bp` to build your solution. The command:

1. Reads `.vscode/settings.json` for `dotnet.defaultSolution`
2. Falls back to finding `.sln` or `.slnx` files
3. Runs `dotnet build` with live output
4. Opens quickfix list on errors

### Unit Testing

Testing uses [neotest](https://github.com/nvim-neotest/neotest) with [neotest-dotnet](https://github.com/Issafalcon/neotest-dotnet).

- `<leader>tr` - Run the test under cursor
- `<leader>td` - Debug the test under cursor
- `<leader>ts` - View test summary panel

## Plugin Highlights

### Core

- **[lazy.nvim](https://github.com/folke/lazy.nvim)** - Plugin manager
- **[mason.nvim](https://github.com/williamboman/mason.nvim)** - LSP/DAP/linter installer
- **[nvim-treesitter](https://github.com/nvim-treesitter/nvim-treesitter)** - Syntax highlighting
- **[nvim-cmp](https://github.com/hrsh7th/nvim-cmp)** - Autocompletion

### Navigation

- **[fzf-lua](https://github.com/ibhagwan/fzf-lua)** - Fuzzy finder
- **[harpoon](https://github.com/ThePrimeagen/harpoon)** - Quick file switching
- **[leap.nvim](https://github.com/ggandor/leap.nvim)** - Fast cursor movement
- **[nvim-tree.lua](https://github.com/nvim-tree/nvim-tree.lua)** - File explorer

### UI

- **[onedark.nvim](https://github.com/navarasu/onedark.nvim)** - Color scheme with C# enhancements
- **[lualine.nvim](https://github.com/nvim-lualine/lualine.nvim)** - Status line
- **[bufferline.nvim](https://github.com/akinsho/bufferline.nvim)** - Tab bar
- **[alpha-nvim](https://github.com/goolord/alpha-nvim)** - Dashboard

### Development

- **[trouble.nvim](https://github.com/folke/trouble.nvim)** - Diagnostics list
- **[gitsigns.nvim](https://github.com/lewis6991/gitsigns.nvim)** - Git integration
- **[todo-comments.nvim](https://github.com/folke/todo-comments.nvim)** - Highlight TODOs
- **[which-key.nvim](https://github.com/folke/which-key.nvim)** - Keybinding hints
- **[rest.nvim](https://github.com/rest-nvim/rest.nvim)** - HTTP client for `.http` files

## macOS Features

- **System clipboard** - Uses `pbcopy`/`pbpaste` for seamless copy/paste
- **ARM64 debugger** - Native Apple Silicon netcoredbg
- **Finder integration** - `:Ofinder` reveals file in Finder
- **Tmux navigation** - Seamless pane switching with vim-tmux-navigator

## Customization

### Adding Plugins

Create a new file in `lua/meon/plugins/` with a lazy.nvim spec:

```lua
return {
  "author/plugin-name",
  config = function()
    require("plugin-name").setup({})
  end,
}
```

### Modifying Keymaps

Edit `lua/meon/core/keymaps.lua` to add or change key bindings.

### Changing Theme

Edit `lua/meon/plugins/colorscheme.lua` to modify colors or switch themes.

## Troubleshooting

### Roslyn not starting

1. Ensure .NET SDK 8.0+ is installed: `dotnet --version`
2. Check Mason installed the server: `:Mason` and look for `roslyn`
3. View LSP logs: `:LspLog`

### Debugger not working

1. Verify netcoredbg path exists: `~/.local/share/nvim/lazy/netcoredbg-macOS-arm64.nvim/netcoredbg/netcoredbg`
2. Check `launch.json` syntax is valid
3. Ensure project is built before debugging

### Plugins not loading

1. Run `:Lazy` to check plugin status
2. Try `:Lazy sync` to update plugins
3. Check for errors: `:messages`

### rest.nvim stalls ~15s on every startup

Its `tree-sitter-http` luarocks dependency failed to build, and a failed build
wipes the rock tree so lazy retries it each launch. Install the build backend
into the hererocks tree once, then restart:

```sh
~/.local/share/nvim/lazy-rocks/hererocks/bin/luarocks install luarocks-build-treesitter-parser
```

## License

MIT
