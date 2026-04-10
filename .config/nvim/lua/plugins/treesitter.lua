return {
  "nvim-treesitter/nvim-treesitter",
  build = ":TSUpdate",
  lazy = false,
  config = function()
    local parsers = { "scala", "lua", "bash", "json", "yaml", "rust", "toml" }
    for _, parser in ipairs(parsers) do
      if not pcall(vim.treesitter.query.get, parser, "highlights") then
        vim.cmd.TSInstall(parser)
      end
    end

    vim.api.nvim_create_autocmd("FileType", {
      group = vim.api.nvim_create_augroup("treesitter_setup", { clear = true }),
      pattern = "*",
      callback = function(event)
        pcall(vim.treesitter.start, event.buf, event.match)
      end,
    })
  end,
}
