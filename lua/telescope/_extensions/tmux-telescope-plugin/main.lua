local pickers = require("telescope.pickers")
local finders = require("telescope.finders")
local actions = require("telescope.actions")
local action_state = require("telescope.actions.state")
local previewers = require("telescope.previewers")
local utils = require("telescope.previewers.utils")
local config = require("telescope.config").values

local log = require("plenary.log"):new()
-- log.level = 'debug'

local M = {}

M.strip_nls = function(lines)
    local res = {}
    local last = nil
    for _, line in pairs(lines) do
        if not (last == "" and line == "") then
            table.insert(res, line)
        end

        last = line
    end
    return res
end

M.capute_pane = function(session_name, win_id, pane)
    log.debug(pane)
    local pane_id = vim.fn.split(pane, ":")[1]
    local command = {
        "silent",
        "!tmux",
        "capture-pane",
        "-t",
        session_name .. ":" .. win_id .. "." .. pane_id,
        "-p",
    }
    log.debug(command)
    local res = vim.api.nvim_exec2(vim.fn.join(command, " "), { output = true })
    res = vim.fn.split(res.output, "\n")
    table.remove(res, 1)
    table.remove(res, 1)
    return pane_id, res
end

M.capute_panes = function(window, session_name)
    local win_id = vim.fn.split(window, ":")[1]
    local command = {
        "silent",
        "!tmux",
        "list-panes",
        "-t",
        session_name .. ":" .. win_id,
    }
    local res = vim.api.nvim_exec2(vim.fn.join(command, " "), { output = true })
    res = vim.fn.split(res.output, "\n")
    table.remove(res, 1)
    table.remove(res, 1)
    local panes = {}
    for _, pane in pairs(res) do
        local pane_id, pane_content = M.capute_pane(session_name, win_id, pane)
        panes[pane_id] = pane_content
    end
    return panes
end

M.show_tmux_sessions = function(opts)
    pickers.new(opts, {
        finder = finders.new_async_job({
            command_generator = function()
                return { "tmux", "list-sessions", "-F", '{ "session_name": "#{session_name}"}' }
            end,
            entry_maker = function(entry)
                log.debug(entry)
                local parsed = vim.json.decode(entry)
                if parsed then
                    log.debug(parsed)
                    return {
                        value = parsed,
                        display = parsed.session_name,
                        ordinal = parsed.session_name
                        -- TODO change ordinal to have the output of `find`?
                    }
                end
            end

        }),
        sorter = config.generic_sorter(opts),
        previewer = previewers.new_buffer_previewer({
            title = "Tmux session",
            define_preview = function(self, entry)
                local command = {
                    "silent",
                    "!tmux",
                    "list-windows",
                    "-t",
                    entry.value.session_name,
                }
                local res = vim.api.nvim_exec2(vim.fn.join(command, " "), { output = true })
                local windows = vim.fn.split(res.output, "\n")
                table.remove(windows, 1)
                table.remove(windows, 1)
                local preview = { "# " .. entry.value.session_name .. ":", windows }
                for _, window in pairs(windows) do
                    local win_id = vim.fn.split(window, ":")[1]
                    local panes = M.capute_panes(window, entry.value.session_name)

                    log.debug("panes", #panes)
                    for pane_id, pane in pairs(panes) do
                        table.insert(preview, "#" .. entry.value.session_name .. ":" .. win_id .. "." .. pane_id)
                        table.insert(preview, M.strip_nls(pane))
                    end
                end
                log.debug(preview)
                vim.api.nvim_buf_set_lines(self.state.bufnr, 0, 0, true, vim.tbl_flatten(preview))
                utils.highlighter(self.state.bufnr, "sh")
            end
        }),
        attach_mappings = function(prompt_bufnr)
            actions.select_default:replace(function()
                local selection = action_state.get_selected_entry()
                actions.close(prompt_bufnr)
                if selection then
                    local command = {
                        "silent",
                        "!tmux",
                        "switch-client",
                        "-t",
                        selection.value.session_name,
                    }
                    log.debug("Selected", command)
                    vim.cmd(vim.fn.join(command, " "))
                end
            end)
            return true
        end

    }):find()
end

log.debug("run the main module")
return M
