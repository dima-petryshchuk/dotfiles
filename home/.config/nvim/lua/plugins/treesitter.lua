return {
  {
    'nvim-treesitter/nvim-treesitter',
    branch = 'main', -- the old master branch is archived; main is the only supported branch now
    build = ':TSUpdate',
    config = function()
      require('nvim-treesitter').install({
        'bash', 'c', 'diff', 'html', 'javascript', 'typescript', 'tsx',
        'json', 'lua', 'luadoc', 'markdown', 'markdown_inline', 'python',
        'query', 'sql', 'vim', 'vimdoc', 'yaml',
      })

      -- main branch dropped the old setup({highlight = {enable = true}}) config;
      -- you start treesitter highlighting per-buffer via core nvim's own API.
      vim.api.nvim_create_autocmd('FileType', {
        pattern = '*',
        callback = function() pcall(vim.treesitter.start) end,
      })
    end,
  },
}
