require("oil").setup({
    default_file_explorer = true,

    view_options = {
        show_hidden = false,
    },

    delete_to_trash = true,

    keymaps = {
        ["<leader>."] = "actions.toggle_hidden",
    },
})

vim.keymap.set("n", "<leader>ff", "<CMD>Oil<CR>", {
    desc = "File Explorer",
})
require('nvim-autopairs').setup{}
require('which-key').setup{}
