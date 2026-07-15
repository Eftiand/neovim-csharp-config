-- Seamless <C-h/j/k/l> navigation between Neovim splits and herdr panes.
--
-- Ported from vim-herdr-navigation (paulbkim-dev/vim-herdr-navigation), itself a
-- port of christoomey/vim-tmux-navigator to herdr's CLI.
--
-- nav() moves between Neovim splits first. At a split edge it hands off to the
-- surrounding multiplexer: herdr when inside a herdr pane ($HERDR_PANE_ID), else
-- tmux ($TMUX) via vim-tmux-navigator's commands, else nothing (plain wincmd
-- already had its chance). This keeps an existing tmux setup working untouched.

local M = {}

local tmux_cmd = { left = "Left", down = "Down", up = "Up", right = "Right" }

function M.nav(wincmd, dir)
  local prev = vim.api.nvim_get_current_win()
  vim.cmd("wincmd " .. wincmd)
  if vim.api.nvim_get_current_win() ~= prev then
    return -- moved within Neovim
  end
  -- At a split edge: cross into the surrounding multiplexer.
  if vim.env.HERDR_PANE_ID and vim.env.HERDR_PANE_ID ~= "" then
    local herdr = vim.env.HERDR_BIN_PATH
    if herdr == nil or herdr == "" then
      herdr = "herdr"
    end
    vim.fn.system({ herdr, "pane", "focus", "--direction", dir, "--current" })
  elseif vim.env.TMUX and vim.env.TMUX ~= "" then
    pcall(vim.cmd, "TmuxNavigate" .. tmux_cmd[dir])
  end
end

return M
