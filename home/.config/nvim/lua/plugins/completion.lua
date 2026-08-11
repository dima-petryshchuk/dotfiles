return {
  {
    'saghen/blink.cmp',
    version = '1.*',
    opts = {
      keymap = { preset = 'default' }, -- <C-y> accept, <C-n>/<C-p> navigate, <C-space> docs
      appearance = { nerd_font_variant = 'mono' }, -- you already have nerd-fonts.hack
      completion = { documentation = { auto_show = true } },
      sources = { default = { 'lsp', 'path', 'buffer' } },
      signature = { enabled = true },
    },
  },
}
