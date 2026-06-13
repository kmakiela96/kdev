return {
  {
    "ibhagwan/fzf-lua",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    config = function()
      local fzf = require("fzf-lua")
      fzf.setup({})

      local function lsp_tabedit(lsp_fn)
        return function()
          local opts = {
            on_list = function(list)
              if #list.items == 1 then
                local item = list.items[1]
                vim.cmd("tabedit " .. item.filename)
                vim.schedule(function()
                  vim.api.nvim_win_set_cursor(0, { item.lnum, item.col - 1 })
                end)
              else
                fzf[lsp_fn == "definition" and "lsp_definitions" or "lsp_references"]({
                  actions = { ["default"] = fzf.actions.file_tabedit },
                })
              end
            end,
          }
          -- vim.lsp.buf.references signature is (context, opts); passing opts
          -- as the first arg makes Neovim try to serialise on_list (a fn) as
          -- LSP context → "Cannot serialise function" RPC error.
          if lsp_fn == "references" then
            vim.lsp.buf.references(nil, opts)
          else
            vim.lsp.buf[lsp_fn](opts)
          end
        end
      end

      vim.keymap.set("n", "gd", lsp_tabedit("definition"))
      vim.keymap.set("n", "gr", lsp_tabedit("references"))
    end,
  },
}
