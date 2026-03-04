return {
	"neovim/nvim-lspconfig",
	event = { "BufReadPre", "BufNewFile" },
	dependencies = {
		"hrsh7th/cmp-nvim-lsp",
		{ "antosha417/nvim-lsp-file-operations", config = true },
		{ "folke/neodev.nvim", opts = {} },
		"williamboman/mason.nvim",
		"williamboman/mason-lspconfig.nvim",
	},
	config = function()
		-- Import cmp-nvim-lsp plugin for enhanced capabilities
		local cmp_nvim_lsp = require("cmp_nvim_lsp")

		-- Import mason-lspconfig plugin safely
		local mason_lspconfig_ok, mason_lspconfig = pcall(require, "mason-lspconfig")
		if not mason_lspconfig_ok then
			vim.notify("mason-lspconfig not found", vim.log.levels.ERROR)
			return
		end

		local keymap = vim.keymap

		-- LSP keybindings (attached when LSP client connects to buffer)
		vim.api.nvim_create_autocmd("LspAttach", {
			group = vim.api.nvim_create_augroup("UserLspConfig", {}),
			callback = function(ev)
				-- Buffer local mappings
				local opts = { buffer = ev.buf, silent = true }

				-- Register with which-key if available
				local wk_ok, wk = pcall(require, "which-key")
				if wk_ok then
					wk.add({
						{ "g", group = "goto", buffer = ev.buf },
						{ "gR", desc = "Show LSP references", buffer = ev.buf },
						{ "gD", desc = "Go to declaration", buffer = ev.buf },
						{ "gd", desc = "Show LSP definitions", buffer = ev.buf },
						{ "gi", desc = "Show LSP implementations", buffer = ev.buf },
						{ "gt", desc = "Show LSP type definitions", buffer = ev.buf },
					})
				end

				-- LSP navigation and actions
				opts.desc = "Show LSP references"
				keymap.set("n", "gR", function()
					require("fzf-lua").lsp_references()
				end, opts)

				-- Override default grr to use fzf-lua instead of quickfix
				opts.desc = "Show LSP references (fzf)"
				keymap.set("n", "grr", function()
					require("fzf-lua").lsp_references()
				end, opts)

				opts.desc = "Go to declaration"
				keymap.set("n", "gD", vim.lsp.buf.declaration, opts)

				opts.desc = "Show LSP definitions"
				keymap.set("n", "gd", function()
					require("fzf-lua").lsp_definitions()
				end, opts)

				opts.desc = "Show LSP implementations"
				keymap.set("n", "gi", function()
					require("fzf-lua").lsp_implementations()
				end, opts)

				opts.desc = "Show LSP type definitions"
				keymap.set("n", "gt", function()
					require("fzf-lua").lsp_typedefs()
				end, opts)

				opts.desc = "See available code actions"
				keymap.set({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, opts)

				opts.desc = "Smart rename"
				keymap.set("n", "<leader>rn", function()
					vim.lsp.buf.rename()
					-- Wait a bit for LSP to apply changes, then save all modified buffers
					vim.defer_fn(function()
						vim.cmd("silent! wall")
					end, 100)
				end, opts)

				opts.desc = "Show buffer diagnostics"
				keymap.set("n", "<leader>D", function()
					require("fzf-lua").diagnostics_document()
				end, opts)

				opts.desc = "Show line diagnostics"
				keymap.set("n", "<leader>d", vim.diagnostic.open_float, opts)

				opts.desc = "Go to previous diagnostic"
				keymap.set("n", "[d", vim.diagnostic.goto_prev, opts)

				opts.desc = "Go to next diagnostic"
				keymap.set("n", "]d", vim.diagnostic.goto_next, opts)

				opts.desc = "Show documentation for what is under cursor"
				keymap.set("n", "K", vim.lsp.buf.hover, opts)

				opts.desc = "Restart LSP"
				keymap.set("n", "<leader>rs", "<cmd>LspRestart<cr>", opts)

				-- Use = operator for LSP formatting when available
				vim.bo[ev.buf].formatexpr = "v:lua.vim.lsp.formatexpr()"
			end,
		})

		-- Enhanced LSP capabilities for autocompletion
		local capabilities = cmp_nvim_lsp.default_capabilities()

		-- Diagnostic symbols in the sign column (gutter)
		vim.diagnostic.config({
			virtual_text = true,
			signs = {
				text = {
					[vim.diagnostic.severity.ERROR] = " ",
					[vim.diagnostic.severity.WARN] = " ",
					[vim.diagnostic.severity.HINT] = "󰠠 ",
					[vim.diagnostic.severity.INFO] = " ",
				},
			},
			underline = true,
		})

		-- Make diagnostic colors more vivid (onedark palette)
		vim.api.nvim_set_hl(0, "DiagnosticVirtualTextError", { fg = "#e06c75", bold = true })
		vim.api.nvim_set_hl(0, "DiagnosticVirtualTextWarn", { fg = "#e5c07b", bold = true })
		vim.api.nvim_set_hl(0, "DiagnosticVirtualTextInfo", { fg = "#61afef", bold = true })
		vim.api.nvim_set_hl(0, "DiagnosticVirtualTextHint", { fg = "#98c379", bold = true })

		-- Get list of installed servers from Mason
		local installed_servers = mason_lspconfig.get_installed_servers()

		-- Configure lua_ls with custom settings
		vim.lsp.config("lua_ls", {
			capabilities = capabilities,
			settings = {
				Lua = {
					diagnostics = {
						globals = { "vim" },
					},
					completion = {
						callSnippet = "Replace",
					},
					workspace = {
						checkThirdParty = false,
					},
					telemetry = {
						enable = false,
					},
				},
			},
		})

		-- Configure all other servers with default capabilities
		for _, server_name in ipairs(installed_servers) do
			if server_name ~= "lua_ls" then
				vim.lsp.config(server_name, {
					capabilities = capabilities,
				})
			end
		end

		-- Enable all installed LSP servers using the modern vim.lsp.enable() API
		for _, server_name in ipairs(installed_servers) do
			vim.lsp.enable(server_name)
		end
	end,
}
