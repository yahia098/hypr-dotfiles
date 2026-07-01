vim.g.mapleader = " "
local map = vim.keymap.set

map("n", "<leader>w", "<cmd>w<CR>")
map("n", "<leader>q", "<cmd>q<CR>")
map("n", "<Esc>", "<cmd>noh<CR>")
map({ "n", "v" }, "y", '"+y')
map({ "n", "v" }, "Y", '"+Y')
map("n", "<leader>e", vim.diagnostic.open_float)
map("n", "gd", vim.lsp.buf.definition)
map("n", "gr", vim.lsp.buf.references)
map("n", "K", vim.lsp.buf.hover)
map({ "n", "v" }, "<A-y>", '"+d', { desc = "Cut to system clipboard" })
map("n", "<leader>ff", "<CMD>Oil<CR>", { desc = "Open Oil" })
vim.keymap.set("n", "K", function()
	vim.diagnostic.open_float(nil, {
		focus = true,
		border = "rounded",
	})
end, { desc = "Show diagnostic under cursor" })
vim.keymap.set("n", "<leader>fc", function()
	require("conform").format({ async = true })
end, { desc = "Format code" })
