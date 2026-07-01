-- Java LSP via nvim-jdtls.
--
-- Why a dedicated plugin instead of the generic vim.lsp.enable() loop:
--   * nvim-jdtls registers the `jdt://` URI handler, so go-to-definition /
--     references into JDK and library classes actually open a buffer instead
--     of erroring on the non-file scheme.
--   * It loads OSGi extension bundles — here the CFR/Fernflower/Procyon
--     decompilers — so classes WITHOUT an attached `-sources.jar` show
--     decompiled source.
--
-- jdtls is excluded from the generic enable loop in lspconfig.lua so the two
-- do not both attach. All the shared LSP keymaps (gd, gR, K, <leader>ca, ...)
-- come from the global LspAttach autocmd in lspconfig.lua and apply here too.
return {
	"mfussenegger/nvim-jdtls",
	ft = "java",
	dependencies = { "hrsh7th/cmp-nvim-lsp", "williamboman/mason.nvim", "mfussenegger/nvim-dap" },
	config = function()
		local jdtls = require("jdtls")
		local data = vim.fn.stdpath("data")
		local bundles_dir = data .. "/jdtls-bundles"

		-- Prefer the Mason-installed launcher; fall back to whatever `jdtls` is on PATH.
		local mason_jdtls = data .. "/mason/bin/jdtls"
		local jdtls_cmd = vim.fn.executable(mason_jdtls) == 1 and mason_jdtls or "jdtls"

		local function start()
			local root_markers = {
				"gradlew",
				"mvnw",
				"settings.gradle",
				"settings.gradle.kts",
				"pom.xml",
				"build.gradle",
				"build.gradle.kts",
				".git",
			}
			local root_dir = vim.fs.root(0, root_markers) or vim.fn.getcwd()
			local project_name = vim.fs.basename(root_dir)
			-- One workspace per project (matches the lspconfig jdtls default layout).
			local workspace_dir = vim.fn.stdpath("cache") .. "/jdtls/workspace/" .. project_name

			-- Extension bundles loaded into jdtls:
			--   * decompilers (jdtls-bundles) -> decompiled go-to-definition
			--   * java-debug-adapter          -> registers the `java` DAP adapter
			--   * java-test                   -> test discovery / running
			local mason_pkgs = data .. "/mason/packages"
			local bundles = vim.fn.glob(bundles_dir .. "/*.jar", true, true)
			vim.list_extend(
				bundles,
				vim.fn.glob(
					mason_pkgs .. "/java-debug-adapter/extension/server/com.microsoft.java.debug.plugin-*.jar",
					true,
					true
				)
			)
			-- IMPORTANT: only the *.test.plugin jar is a real OSGi bundle. The other
			-- jars in that dir (runner-with-dependencies, jacocoagent, junit) are
			-- plain jars; passing them makes jdtls's loadBundles throw and abort the
			-- ENTIRE bundle list — which silently kills the java-debug plugin too.
			vim.list_extend(
				bundles,
				vim.fn.glob(mason_pkgs .. "/java-test/extension/server/com.microsoft.java.test.plugin-*.jar", true, true)
			)

			local capabilities = require("cmp_nvim_lsp").default_capabilities()
			local extendedClientCapabilities = jdtls.extendedClientCapabilities
			extendedClientCapabilities.resolveAdditionalTextEditsSupport = true

			jdtls.start_or_attach({
				cmd = { jdtls_cmd, "-data", workspace_dir },
				root_dir = root_dir,
				capabilities = capabilities,
				init_options = {
					bundles = bundles,
					extendedClientCapabilities = extendedClientCapabilities,
				},
				settings = {
					java = {
						-- Let jdtls download/attach sources jars automatically; the
						-- decompiler bundles cover deps that ship none.
						maven = { downloadSources = true },
						eclipse = { downloadSources = true },
					},
				},
			})

			-- Register the `java` nvim-dap adapter immediately (not via on_attach,
			-- which depends on client timing). setup_dap() makes NO server call --
			-- it just registers the adapter function, which only talks to jdtls at
			-- run time -- so eager registration is safe. This is what lets Overseer's
			-- <leader>or route launch.json "type": "java" configs to dap.run().
			--
			-- NOTE: deliberately NOT calling setup_dap_main_class_configs() here --
			-- it fires vscode.java.resolveMainClass immediately, before the project
			-- has imported, spamming "No LSP client found" errors. launch.json
			-- already provides mainClass, so we don't need the discovered configs.
			require("jdtls").setup_dap({ hotcodereplace = "auto" })
		end

		-- Attach on every Java buffer opened this session...
		vim.api.nvim_create_autocmd("FileType", {
			pattern = "java",
			group = vim.api.nvim_create_augroup("UserJdtls", { clear = true }),
			callback = start,
		})
		-- ...and the current one, whose FileType already fired before this loaded.
		if vim.bo.filetype == "java" then
			start()
		end
	end,
}
