return {
	"williamboman/mason.nvim",
	lazy = false,
	dependencies = {
		"williamboman/mason-lspconfig.nvim",
		"WhoIsSethDaniel/mason-tool-installer.nvim",
	},
	config = function()
		-- import mason
		local mason = require("mason")

		-- import mason-lspconfig
		local mason_lspconfig = require("mason-lspconfig")

		local mason_tool_installer = require("mason-tool-installer")

		-- enable mason and configure icons
		mason.setup({
			ui = {
				icons = {
					package_installed = "✓",
					package_pending = "➜",
					package_uninstalled = "✗",
				},
			},
			registries = {
				"github:mason-org/mason-registry",
				"github:Crashdummyy/mason-registry",
			},
		})

		mason_lspconfig.setup({
			-- list of servers for mason to install
			ensure_installed = {
				"ts_ls", -- TypeScript/JavaScript
				"cssls", -- CSS
				"html", -- HTML
				"pyright", -- Python
				"gopls", -- Go
			},
		})
		mason_tool_installer.setup({
			ensure_installed = {
				"eslint", -- JavaScript linter
				"html", -- HTML
				"jsonls", -- JSON
				"prettier", -- prettier formatter
				"stylua",
				"ruff", -- Python linter + formatter
				"debugpy", -- Python debugger
				"delve", -- Go debugger
			},
		})
	end,
}
