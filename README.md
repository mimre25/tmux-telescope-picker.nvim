# TMUX session picker

This repository contains a [telescope](https://github.com/nvim-telescope/telescope.nvim) extension that lets you pick a tmux session.


## Demo

![[]](demo_screenshot.png)


## Installation
With [lazy.nvim](https://github.com/folke/lazy.nvim):
```lua
-- Add this to your lazy.lua
{
    'mimre25/tmux-telescope-picker.nvim'
    dependencies = { 'nvim-telescope/telescope.nvim' } -- duh
}

-- call this _somewhere_
telescope.load_extension("tmux")
-- now Telescope tmux show_sessions is available


-- add a keymap
vim.keymap.set("n", "<leader>t", function() telescope.extensions.tmux.show_sessions() end)

```

## API
The plugin adds a picker `Telescope tmux show_sessions`.
Alternatively, the same picker can be used via `telescope.extensions.tmux.show_sessions()`.


# WIP Warning
This is an early hacky script that is very much WIP and might undergo changes.
I've built it primarily for my own use case, which is switching between TMUX sessions quickly.
Trust me, it's faster than `prefix-S` followed by `/` and searching.

