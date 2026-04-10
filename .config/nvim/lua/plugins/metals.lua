return {
  "scalameta/nvim-metals",
  dependencies = { "nvim-lua/plenary.nvim", "saghen/blink.cmp" },
  ft = { "scala", "sbt", "java" },
  config = function()
    local metals_config = require("metals").bare_config()

    local jdk17_path = vim.fn.system("jenv prefix 17"):gsub("%s+", "")

    metals_config.settings = {
      javaHome = jdk17_path,
      serverProperties = {
        "--add-opens=jdk.compiler/com.sun.tools.javac.api=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.code=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.comp=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.file=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.main=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.model=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.parser=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.processing=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.tree=ALL-UNNAMED",
        "--add-opens=jdk.compiler/com.sun.tools.javac.util=ALL-UNNAMED",
      },
      automaticImportBuild = "initial",
      showImplicitArguments = false,
      showInferredType = false,
      excludedPackages = {
        "akka.actor.typed.javadsl",
        "com.github.swagger.akka.javadsl",
      },
      superMethodLensesEnabled = false,
      inlayHints = {
        implicitArguments = { enable = false },
        implicitConversions = { enable = false },
        typeParameters = { enable = false },
        inferredTypes = { enable = false },
        hintsInPatternMatch = { enable = false },
      },
      enableSemanticHighlighting = false,
    }

    metals_config.init_options.statusBarProvider = "on"
    local ok, blink = pcall(require, "blink.cmp")
    if ok then
      metals_config.capabilities = blink.get_lsp_capabilities()
    end

    vim.api.nvim_create_autocmd("FileType", {
      pattern = { "scala", "sbt", "java" },
      callback = function()
        require("metals").initialize_or_attach(metals_config)
      end,
    })
  end,
}
