-- HTTP client for *.http files (REST Client / IntelliJ .http format).
--
-- Dependencies (nvim-nio, mimetypes, xml2lua, fidget.nvim, tree-sitter-http)
-- are declared in rest.nvim's rockspec and installed by lazy.nvim through
-- hererocks, so `curl` and the tree-sitter CLI have to be on $PATH.
--
-- On a fresh machine the tree-sitter-http rock fails with
-- "module 'luarocks.build.treesitter-parser' not found": luarocks installs the
-- build backend into the plugin's own rock tree, where it cannot load itself
-- from. Install it into the hererocks tree once, then restart:
--
--   ~/.local/share/nvim/lazy-rocks/hererocks/bin/luarocks \
--     install luarocks-build-treesitter-parser
--
-- A failed build wipes lazy-rocks/rest.nvim, so lazy retries it on every
-- startup until it succeeds - a ~15s stall is the symptom.
--
-- The `http` treesitter parser is also installed via meon.plugins.treesitter so
-- that highlighting works without the rock.

---Pick a named request (`# @name foo`) in the current buffer and run it.
local function pick_request()
	local names = require("rest-nvim.parser").get_request_names(0)
	if #names == 0 then
		vim.notify("No named requests in this file (add `# @name foo` above a request)", vim.log.levels.WARN)
		return
	end
	vim.ui.select(names, { prompt = "Run request" }, function(name)
		if name then
			vim.cmd("Rest run " .. vim.fn.escape(name, " "))
		end
	end)
end

return {
	"rest-nvim/rest.nvim",
	ft = "http",
	cmd = "Rest",
	keys = {
		{ "<leader>Rr", "<Cmd>Rest run<CR>", desc = "Run request under cursor", ft = "http" },
		{ "<leader>Rf", pick_request, desc = "Find and run named request", ft = "http" },
		{ "<leader>Rl", "<Cmd>Rest last<CR>", desc = "Re-run last request" },
		{ "<leader>Ro", "<Cmd>Rest open<CR>", desc = "Open response pane" },
		{ "<leader>Rc", "<Cmd>Rest curl yank<CR>", desc = "Yank request as curl", ft = "http" },
	},
	init = function()
		-- rest.nvim is configured through vim.g, it has no setup() call.
		---@type rest.Opts
		vim.g.rest_nvim = {
			clients = {
				curl = {
					statistics = {
						{ id = "response_code", winbar = "code", title = "Status" },
						{ id = "time_total", winbar = "take", title = "Time taken" },
						{ id = "size_download", winbar = "size", title = "Download size" },
					},
				},
			},
		}
	end,
}
