-- managed by kdev
vim.opt.clipboard = "unnamedplus"
vim.opt.termguicolors = true
vim.opt.rtp:prepend(vim.fn.stdpath("data") .. "/site")

local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  vim.fn.system({
    "git", "clone", "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  { import = "plugins" },
})

-- Diagnostics appearance
vim.diagnostic.config({
  virtual_text = false,
  signs = true,
  underline = true,
  update_in_insert = true,
  severity_sort = true,
  float = {
    border = "rounded",
    source = true,
    header = "",
    prefix = "",
  },
})

vim.opt.signcolumn = "yes"
vim.opt.number = true

-- Tab navigation
vim.keymap.set("n", "<Tab>",   "gt",              { desc = "Next tab" })
vim.keymap.set("n", "<S-Tab>", "gT",              { desc = "Prev tab" })
vim.keymap.set("n", "<C-]>",   "<cmd>tab tag<CR>", { desc = "Jump to tag in new tab" })
