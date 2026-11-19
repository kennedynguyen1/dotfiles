vim.pack.add { 'https://github.com/sindrets/diffview.nvim' }
require('diffview').setup { use_icons = vim.g.have_nerd_font }

vim.keymap.set('n', '<leader>do', '<cmd>DiffviewOpen<CR>', { desc = '[D]iffview [O]pen' })
vim.keymap.set('n', '<leader>dc', '<cmd>DiffviewClose<CR>', { desc = '[D]iffview [C]lose' })
