-- vim-tmux-navigator, extended for herdr panes.
--
-- We keep vim-tmux-navigator installed for its TmuxNavigate* commands (used as
-- the tmux fallback in herdr-nav), but disable its default mappings so our
-- herdr-aware <C-h/j/k/l> are the single source of truth. See util/herdr-nav.
return {
  "christoomey/vim-tmux-navigator", -- tmux & split window navigation
  lazy = false,
  init = function()
    vim.g.tmux_navigator_no_mappings = 1
  end,
  config = function()
    local nav = require("meon.util.herdr-nav").nav
    local dirs = {
      { "<C-h>", "h", "left", "Navigate left (vim/herdr)" },
      { "<C-j>", "j", "down", "Navigate down (vim/herdr)" },
      { "<C-k>", "k", "up", "Navigate up (vim/herdr)" },
      { "<C-l>", "l", "right", "Navigate right (vim/herdr)" },
    }
    for _, d in ipairs(dirs) do
      local lhs, wincmd, dir, desc = d[1], d[2], d[3], d[4]
      vim.keymap.set("n", lhs, function()
        nav(wincmd, dir)
      end, { silent = true, noremap = true, desc = desc })
    end
  end,
}
