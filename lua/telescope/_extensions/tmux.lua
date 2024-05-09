local has_telescope, telescope = pcall(require, 'telescope')
local main = require('telescope._extensions.tmux-telescope-plugin.main')
if not has_telescope then
  error('This plugins requires nvim-telescope/telescope.nvim')
end


return telescope.register_extension {
  exports = {
    show_sessions = main.show_tmux_sessions
  },
}
