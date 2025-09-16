
local internal = require("make.internal")
local state = require("make.state")

local M = {}

local MAKEFILE_NAME = "Makefile"

local default_opts = {
    build_types = { "debug", "release" },
    build_type = "debug",
    notifications = {
        ["on_build_target_changed"] = true,
        ["on_build_type_changed"] = true,
    },
}

local resolve = function(opt)
    if type(opt) == "function" then
        return opt()
    else
        return opt
    end
end

function M.setup(opts)
    opts = opts or {}
    state.build_types = resolve(opts.build_types) or default_opts.build_types
    state.build_type = resolve(opts.default_build_type) or default_opts.build_type
    state.build_target = ""
    state.notifications = state.notifications or {}

    opts.notifications = resolve(opts.notifications) or default_opts.notifications
    for notification, enabled in pairs(opts.notifications) do
        state.notifications[notification] = enabled
    end

    --[[
    opts.user_args = resolve(opts.user_args) or {}
    for _, arg in ipairs(opts.user_args) do
        state.user_args = string.format("%s %s", state.user_args, arg)
    end
    --]]

    vim.api.nvim_create_user_command("MakeBuild", function()
        M.build_project()
    end, {})

    state.is_setup = true
end

function M.is_setup()
    return state.is_setup
end

function M.is_make_project()
    return vim.fn.glob(MAKEFILE_NAME) ~= ""
end

function M.set_build_type(build_type)
    state.build_type = build_type
    if state.notifications.on_build_type_changed then
        vim.notify(string.format("build type set to '%s'", build_type), vim.log.levels.INFO)
    end
end

function M.get_build_type()
    return state.build_type
end

function M.get_build_types()
    return state.build_types
end

function M.set_build_target(build_target)
    state.build_target = build_target
    if state.notifications.on_build_target_changed then
        vim.notify(string.format("build target changed to '%s'", build_target), vim.log.levels.INFO)
    end
end

function M.get_build_target()
    return state.build_target
end

function M.set_notification_enabled(notification, enabled)
    state.notifications = state.notifications or {}
    state.notifications[notification] = enabled
end

function M.make_clean()
    internal._execute_command("make clean")
end

function M.build_project()
    local command = internal._create_build_command(
        M.get_build_type()
    )
    internal._execute_command(command)
end

function M.get_target_binary_path(build_target_name)
    if M.get_build_target() == "" then
        vim.notify("no make build target set", vim.log.levels.ERROR)
        return
    end
    if M.get_build_type() == "" then
        vim.notify("no make build type set", vim.log.levels.ERROR)
        return
    end
    return string.format("%s/%s", vim.fn.getcwd(), build_target_name)
end

function M.run_build_target()
    local command = M.get_target_binary_path(M.get_build_target())
    internal._execute_command(command)
end

function M.get_build_target_names()
    local output = vim.fn.systemlist("make targets")

    local build_targets = {}
    for i=1, #output do
        table.insert(build_targets, output[i])
    end
    return build_targets
end

return M

