local conform = require("conform")

conform.setup({
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
