return {
	"navarasu/onedark.nvim",
	priority = 1000,
	config = function()
		require("onedark").setup({
			style = "warmer",
			transparent = true,
			colors = {
				bg0 = "#181A1F",
				purple = "#D55FDE",
				yellow = "#F5C876",
				blue = "#61AFEF",
				green = "#89CA78",
				cyan = "#58C1CF",
				red = "#EF596F",
				orange = "#F58838",
				dark_yellow = "#D19A66",

				--red = "#D19A66",
				--cyan = "#DE5D68",
			},
			highlights = {
				["@variable.member"] = { fg = "$red" },
				["@variable.parameter"] = { fg = "$dark_yellow" },
				["@property"] = { fg = "$red" },
				-- ["@constuctor"] = { fmt= "" },
				["@lsp.type.property"] = { fg = "$red" },
				["@lsp.type.parameter"] = { fg = "$dark_yellow" },
				["@lsp.type.interface"] = { fg = "$orange" },
				["@lsp.type.function"] = { fg = "$blue" },
				["@keyword.modifier.c_sharp"] = { fg = "$purple" },
				["@type.builtin"] = { fg = "$purple" },
				["@constant.builtin"] = { fg = "$purple" },
				-- Comments
				["Comment"] = { fg = "#5C6370" },
				["@comment"] = { fg = "#5C6370" },
				-- JSX/TSX/HTML highlighting
				["@tag"] = { fg = "$yellow" }, -- Custom components (PascalCase)
				["@tag.builtin"] = { fg = "$red" }, -- Built-in HTML tags (lowercase)
				["@tag.delimiter"] = { fg = "$cyan" },
				["@tag.attribute"] = { fg = "$dark_yellow" },
				["@constructor.tsx"] = { fg = "$yellow" },
				["@tag.tsx"] = { fg = "$yellow" },
				["@tag.builtin.tsx"] = { fg = "$red" },
				-- Python highlighting
				["@function.call"] = { fg = "$blue" },
				["@function.method.call"] = { fg = "$blue" },
				["@attribute"] = { fg = "$red" },
				["@function.call.python"] = { fg = "$blue" },
				["@function.method.call.python"] = { fg = "$blue" },
				["@function.python"] = { fg = "$blue" },
				["@function.method.python"] = { fg = "$blue" },
				["@type.python"] = { fg = "$yellow" },
				["@constant.builtin.python"] = { fg = "$orange" },
				["@attribute.python"] = { fg = "$blue" },
				["@constructor.python"] = { fg = "$yellow" },
				["@variable.builtin.python"] = { fg = "$dark_yellow" },
			},
		})
		vim.cmd("colorscheme onedark")
	end,
}
