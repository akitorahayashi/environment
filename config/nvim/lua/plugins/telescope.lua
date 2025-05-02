return {
  'nvim-telescope/telescope.nvim',
  tag = '0.1.6', -- 特定のバージョンを指定 (任意)
  dependencies = { 'nvim-lua/plenary.nvim' },
  config = function()
    local telescope = require('telescope')
    local actions = require('telescope.actions')

    telescope.setup({
      defaults = {
        -- デフォルト設定をここに記述 (例: mappings)
        mappings = {
          i = {
            ["<C-j>"] = actions.move_selection_next,
            ["<C-k>"] = actions.move_selection_previous,
            ["<esc>"] = actions.close,
          },
          n = {
            ["q"] = actions.close,
          }
        }
      },
      pickers = {
        -- pickerごとの設定 (例: find_files)
        find_files = {
          theme = "dropdown", -- 見た目のテーマ
          hidden = true, -- 隠しファイルも表示
          -- find_command = {'rg', '--files', '--hidden', '--glob', '!.git/'} -- ripgrepを使う場合はコメントアウト解除
        }
      },
      extensions = {
        -- 拡張機能の設定 (例: fzf)
      }
    })

    -- キーマッピング例
    local builtin = require('telescope.builtin')
    vim.keymap.set('n', '<leader>ff', builtin.find_files, { desc = '[F]ind [F]iles' })
    vim.keymap.set('n', '<leader>fg', builtin.live_grep, { desc = '[F]ind by [G]rep' })
    vim.keymap.set('n', '<leader>fb', builtin.buffers, { desc = '[F]ind [B]uffers' })
    vim.keymap.set('n', '<leader>fh', builtin.help_tags, { desc = '[F]ind [H]elp' })
  end,
} 