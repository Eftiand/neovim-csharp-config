vim.cmd("let g:netrw_liststyle = 3")

-- Disable slow built-in matchparen (bracket highlighting on every cursor move)
-- Profile showed it accounts for ~95% of editing overhead (261 calls, 0.042s)
vim.g.loaded_matchparen = 1

local opt = vim.opt

-- Faster UI responsiveness (CursorHold, gitsigns, diagnostics)
opt.updatetime = 250
opt.ttimeoutlen = 10

-- Cache compiled Lua modules for faster startup
if vim.loader then
	vim.loader.enable()
end

-- Store more recent files in shada
opt.shada = "!,'1000,<50,s10,h"

opt.relativenumber = true
opt.number = true

-- tab & indentation
opt.tabstop = 2
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

opt.wrap = false

opt.ignorecase = true
opt.smartcase = true

opt.cursorline = true
opt.cmdheight = 0

opt.termguicolors = true
opt.background = "dark"
opt.signcolumn = "yes"

opt.backspace = "indent,eol,start"

vim.opt.clipboard = "unnamedplus"

-- Ensure macOS clipboard provider is used
vim.g.clipboard = {
  name = 'macOS-clipboard',
  copy = {
    ['+'] = 'pbcopy',
    ['*'] = 'pbcopy',
  },
  paste = {
    ['+'] = 'pbpaste',
    ['*'] = 'pbpaste',
  },
  cache_enabled = 0,
}

opt.splitright = true
opt.splitbelow = true

-- Autosave is handled by auto-save.nvim (debounced). A raw InsertLeave
-- `write` autocmd used to live here and fired a second, undebounced,
-- synchronous write on every insert-leave.

-- Auto-reload files when changed externally
opt.autoread = true
vim.api.nvim_create_autocmd({ "FocusGained", "BufEnter" }, {
	pattern = "*",
	command = "checktime",
})

vim.api.nvim_create_user_command('Ofinder',
    function()
        local path = vim.api.nvim_buf_get_name(0)
        os.execute('open -R ' .. path)
    end,
    {}
)

-- Set commentstring for JSON files (enables gcc commenting)
vim.api.nvim_create_autocmd("FileType", {
	pattern = { "json", "jsonc" },
	callback = function()
		vim.bo.commentstring = "// %s"
	end,
})

-- Disk write reduction. Every buffer write used to also create and delete a
-- backup copy; with autosave running that doubled the file events for no
-- benefit. Persistent undo replaces what the backup was protecting against.
opt.writebackup = false
opt.undofile = true

-- Plugin logs never rotated and had grown to ~74 MB combined. Roslyn reports
-- NuGet advisories and unresolved-dependency warnings on every didSave, none
-- of which are actionable from inside the editor.
vim.lsp.log.set_level(vim.log.levels.ERROR)

vim.api.nvim_create_autocmd("VimEnter", {
	once = true,
	callback = function()
		local logdir = vim.fn.stdpath("log")
		local limit = 5 * 1024 * 1024
		vim.uv.fs_scandir(logdir, function(err, dir)
			if err or not dir then
				return
			end
			while true do
				local name, typ = vim.uv.fs_scandir_next(dir)
				if not name then
					return
				end
				if typ == "file" and name:match("%.log$") then
					local path = logdir .. "/" .. name
					local stat = vim.uv.fs_stat(path)
					if stat and stat.size > limit then
						local fd = vim.uv.fs_open(path, "w", 420)
						if fd then
							vim.uv.fs_close(fd)
						end
					end
				end
			end
		end)
	end,
})
