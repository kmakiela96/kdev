return {
  {
    "nanozuki/tabby.nvim",
    event = "VimEnter",
    config = function()
      require("tabby").setup()
    end,
  },
}
