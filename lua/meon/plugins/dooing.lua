return {
    "atiladefreitas/dooing",
    keys = { "<leader>st", "<leader>sT" },
    config = function()
        require("dooing").setup({
            window = {
                width = 180,
                height = 40,
            },
            keymaps = {
                toggle_window = "<leader>st",
                open_project_todo = "<leader>sT",
            },
        })
    end,
}
