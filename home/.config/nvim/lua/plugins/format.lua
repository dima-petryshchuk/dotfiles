return {
  {
    'stevearc/conform.nvim',
    event = 'BufWritePre',
    cmd = 'ConformInfo',
    keys = {
      { '<leader>F', function() require('conform').format({ async = true }) end, desc = 'Format Buffer' },
    },
    opts = {
      format_on_save = { timeout_ms = 2000, lsp_format = 'fallback' },
      formatters_by_ft = {
        lua = { 'stylua' },
        javascript = { 'prettier' },
        typescript = { 'prettier' },
        javascriptreact = { 'prettier' },
        typescriptreact = { 'prettier' },
        json = { 'prettier' },
        jsonc = { 'prettier' },
        css = { 'prettier' },
        html = { 'prettier' },
        markdown = { 'prettier' },
        yaml = { 'prettier' },
      },
    },
  },
}
