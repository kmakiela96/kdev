return {
  {
    "saghen/blink.cmp",
    version = "v1.*",
    lazy = false,
    opts = {
      keymap = { preset = "default" },
      completion = {
        menu = {
          border = "rounded",
          auto_show = true,
        },
        documentation = {
          auto_show = true,
          auto_show_delay_ms = 200,
          window = { border = "rounded" },
        },
        ghost_text = { enabled = true },
      },
      signature = {
        enabled = true,
        window = { border = "rounded" },
      },
      sources = {
        default = { "lsp", "path", "snippets", "buffer" },
      },
      appearance = {
        nerd_font_variant = "mono",
      },
    },
  },
}
