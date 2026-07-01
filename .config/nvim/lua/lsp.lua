require("mason").setup()
require("mason-lspconfig").setup({
    ensure_installed = {
        "clangd",
        "pyright",
        "lua_ls",
    },
})
local blink =require('blink.cmp')
blink.setup({
    enabled = function()
        return next(vim.lsp.get_clients({ bufnr = 0 })) ~= nil
    end,
    keymap = {
        preset = "default",
    },
    appearance = {
        nerd_font_variant = "mono",
    },
})
local capabilities = blink.get_lsp_capabilities()

vim.lsp.config("clangd", {
    capabilities = capabilities,
})

vim.lsp.config("pyright", {
    capabilities = capabilities,
})

vim.lsp.config("lua_ls", {
    capabilities = capabilities,
})

vim.lsp.enable({
    "clangd",
    "pyright",
    "lua_ls",
})
vim.diagnostic.config({
    virtual_text = {
        prefix = "●",
        spacing = 2,
    },
    signs = true,
    underline = true,
    update_in_insert = false,
    severity_sort = true,
    float = {
        border = "rounded",
        source = true,
    },
})
require("conform").setup({
    formatters_by_ft = {
        cpp = { "clang_format" },
        c = { "clang_format" },

        lua = { "stylua" },

        python = { "black" },
    },

    format_on_save = {
        timeout_ms = 2000,
        lsp_fallback = true,
    },
})
