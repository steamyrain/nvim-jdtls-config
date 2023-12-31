-- See `:help vim.lsp.start_client` for an overview of the supported `config` options.
local JDTLS_DIR = vim.fn.stdpath 'data' .. '/jdtls/'
local PROJECT_NAME = vim.fn.fnamemodify(vim.fn.getcwd(), ':p:h:t')
local WORKSPACE_DIR = '/home/rain/workspace/' .. PROJECT_NAME
local LOMBOK_JAR = 'lombok.jar'
local JAVA_DEBUG_DIR = '/home/rain/libraries/java/java-debug/com.microsoft.java.debug.plugin/target/'

local attach_dap = function ()
    local dap = require('dap')
    dap.configurations.java = {
        {
            type = 'java',
            request = 'attach',
            name = 'Debug (Attach) - Remote',
            hostName = '127.0.0.1',
            port = 5005,
        },
    }
    dap.continue()
end

local toggle_breakpoint = function ()
    local dap = require('dap')
    dap.toggle_breakpoint()
end

local dap_widget_scopes = function() 
    local widgets = require('dap.ui.widgets')
    widgets.centered_float(widgets.scopes)
end

local on_attach = function(_, bufnr)
  local bufopts = { noremap = true, silent = true, buffer = bufnr }
  vim.keymap.set('n', 'gD', vim.lsp.buf.declaration, bufopts)
  vim.keymap.set('n', 'gd', vim.lsp.buf.definition, bufopts)
  vim.keymap.set('n', 'K', vim.lsp.buf.hover, bufopts)
  vim.keymap.set('n', 'gi', vim.lsp.buf.implementation, bufopts)
  vim.keymap.set('n', '<C-k>', vim.lsp.buf.signature_help, bufopts)
  vim.keymap.set('n', '<space>wa', vim.lsp.buf.add_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wr', vim.lsp.buf.remove_workspace_folder, bufopts)
  vim.keymap.set('n', '<space>wl', function()
    print(vim.inspect(vim.lsp.buf.list_workspace_folders()))
  end, bufopts)
  vim.keymap.set('n', '<c-D>', vim.lsp.buf.type_definition, bufopts)
  vim.keymap.set('n', '<c-rn>', vim.lsp.buf.rename, bufopts)
  vim.keymap.set('n', '<c-ca>', vim.lsp.buf.code_action, bufopts)
  vim.keymap.set('n', 'gr', vim.lsp.buf.references, bufopts)
  vim.keymap.set('n', '<c-f>', function()
    vim.lsp.buf.format { async = true }
  end, bufopts)
  vim.keymap.set('n', '<leader>Da', attach_dap, {noremap = true, silent = false, buffer = bufnr})
  vim.keymap.set('n', '<leader>Bb', toggle_breakpoint, bufopts)
  vim.keymap.set('n', '<leader>Ws', dap_widget_scopes, bufopts)
end

local lsp_flags = {
    debounce_text_changes = 150,
}

local capabilities = vim.lsp.protocol.make_client_capabilities()
capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

local config = {
    -- The command that starts the language server
    -- See: https://github.com/eclipse/eclipse.jdt.ls#running-from-the-command-line
    cmd = {

        'java',
        '-Declipse.application=org.eclipse.jdt.ls.core.id1',
        '-Dosgi.bundles.defaultStartLevel=4',
        '-Declipse.product=org.eclipse.jdt.ls.core.product',
        '-Dlog.protocol=true',
        '-Dlog.level=ALL',
        '-Xms1g',
        '--add-modules=ALL-SYSTEM',
        '--add-opens', 'java.base/java.util=ALL-UNNAMED',
        '--add-opens', 'java.base/java.lang=ALL-UNNAMED',
        '-javaagent:' .. JDTLS_DIR .. LOMBOK_JAR,
        '-Xbootclasspath/a:' .. JDTLS_DIR .. LOMBOK_JAR,
        '-jar', JDTLS_DIR .. 'plugins/org.eclipse.equinox.launcher_1.6.600.v20231106-1826.jar',
        '-configuration', JDTLS_DIR .. 'config_linux',
        '-data', WORKSPACE_DIR
    },
    -- This is the default if not provided, you can remove it. Or adjust as needed.
    -- One dedicated LSP server & client will be started per unique root_dir
    root_dir = require('jdtls.setup').find_root({ '.git', 'mvnw', 'gradlew' }),
    -- Here you can configure eclipse.jdt.ls specific settings
    -- See https://github.com/eclipse/eclipse.jdt.ls/wiki/Running-the-JAVA-LS-server-from-the-command-line#initialize-request
    -- for a list of options
    settings = {
        java = {
        }
    },
    -- Language server `initializationOptions`
    -- You need to extend the `bundles` with paths to jar files
    -- if you want to use additional eclipse.jdt.ls plugins.
    --
    -- See https://github.com/mfussenegger/nvim-jdtls#java-debug-installation
    --
    -- If you don't plan on using the debugger or other eclipse.jdt.ls plugins you can remove this
    init_options = {
        bundles = {
            vim.fn.glob(JAVA_DEBUG_DIR .. 'com.microsoft.java.debug.plugin-*.jar'),
        },
    },
    on_attach = on_attach,
    flags = lsp_flags,
    -- capabilities
    capabilities = {
        capabilities,
    }
}


-- This starts a new client & server,
-- or attaches to an existing client & server depending on the `root_dir`.
require('jdtls').start_or_attach(config)
