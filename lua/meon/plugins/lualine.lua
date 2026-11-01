-- Build status state (global so keymaps can update it)
_G.build_status = {
	running = false,
	message = "",
	level = "info", -- "info", "ok", "error"
}

-- Component function for lualine
local function build_component()
	local bs = _G.build_status
	if bs.running then
		return "⏳ Building..."
	elseif bs.message ~= "" then
		return bs.message
	end
	return ""
end

-- Color based on status
local function build_color()
	local bs = _G.build_status
	if bs.running then
		return { fg = "#e6db74" } -- yellow
	elseif bs.level == "ok" then
		return { fg = "#a6e22e" } -- green
	elseif bs.level == "error" then
		return { fg = "#f92672" } -- red
	end
	return {}
end

-- DAP exception mode component
local function dap_exception_component()
	local mode = _G.dap_exception_mode
	if not mode or mode == "unhandled" then
		return ""
	elseif mode == "user-unhandled" then
		return "Ex:user"
	else
		return "Ex:ALL"
	end
end

local function dap_exception_color()
	local mode = _G.dap_exception_mode
	if mode == "all" then
		return { fg = "#f92672" } -- red
	elseif mode == "user-unhandled" then
		return { fg = "#e6db74" } -- yellow
	end
	return {}
end

return {
	"nvim-lualine/lualine.nvim",
	dependencies = { "nvim-tree/nvim-web-devicons" },
	opts = {
		options = {
			theme = "ayu_dark",
		},
		sections = {
			lualine_x = {
				{ dap_exception_component, color = dap_exception_color },
				{ build_component, color = build_color },
				"fileformat",
				"filetype",
			},
		},
	},
}
