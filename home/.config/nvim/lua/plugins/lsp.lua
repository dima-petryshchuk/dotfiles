return {
  {
    'neovim/nvim-lspconfig',
    dependencies = {
      { 'mason-org/mason.nvim', opts = {} },
      'mason-org/mason-lspconfig.nvim',
      'WhoIsSethDaniel/mason-tool-installer.nvim',
      { 'j-hui/fidget.nvim', opts = {} }, -- lsp progress spinner
    },
    config = function()
      require('mason').setup()

      -- installs + enables these LSP servers automatically (mason-lspconfig
      -- v2 default automatic_enable = true calls vim.lsp.enable() for each)
      require('mason-lspconfig').setup({
        ensure_installed = { 'lua_ls', 'ts_ls', 'jsonls', 'tailwindcss', 'eslint' },
      })

      -- non-LSP CLI tools (formatters) installed the same way, see format.lua
      require('mason-tool-installer').setup({
        ensure_installed = { 'stylua', 'prettier' },
      })

      vim.diagnostic.config({
        virtual_text = { prefix = '●' },
        severity_sort = true,
      })

      -- nvim 0.11+ ships default LSP keymaps once a client attaches:
      -- grn rename, gra code action, grr references, gri implementation,
      -- gO document symbols, K hover, ]d / [d diagnostic nav.
      -- Your existing `gd` (snacks picker) will now actually resolve too.
    end,
  },
}
