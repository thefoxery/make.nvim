
local PLUGIN_NAME = "make.nvim"

local internal = require("make.internal")
local state = require("make.state")

local M = {}

local default_opts = {
    build_types = { "debug", "release" },
    build_type = "debug",
    make = {
        targets_target_name = "targets",
    },
}

function M.setup(user_opts)
    user_opts = user_opts or {}
    user_opts.make = user_opts.make or {}

    state.build_types = internal._resolve(user_opts.build_types) or default_opts.build_types
    state.build_type = internal._resolve(user_opts.default_build_type) or default_opts.build_type
    state.make = state.make or {}
    state.make.targets_target_name = internal._resolve(user_opts.make.targets_target_name) or default_opts.make.targets_target_name
    state.build_target = ""

    vim.api.nvim_create_user_command("MakeBuild", function()
        M.build_project()
    end, {})

    state.is_setup = true
end

function M.is_setup()
    return state.is_setup
end

function M.is_project_directory()
    return vim.fn.glob(internal._MAKEFILE_NAME) ~= ""
end

function M.get_build_system_type()
    return "Make"
end

function M.get_build_types()
    return state.build_types
end

function M.get_build_type()
    return state.build_type
end

function M.set_build_type(build_type)
    state.build_type = build_type
end

function M.get_build_targets()
    if state.make == nil or state.make.targets_target_name == nil then
        vim.notify(string.format("[%s] Trying to get build targets but the specificed target name '%s' is invalid", PLUGIN_NAME), vim.log.levels.ERROR)
        return {}
    end
    local output = vim.fn.systemlist(string.format("make %s", state.make.targets_target_name))

    local build_targets = {}
    for i=1, #output do
        table.insert(build_targets, output[i])
    end
    return build_targets
end

function M.get_build_target()
    return state.build_target
end

function M.set_build_target(build_target)
    state.build_target = build_target
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

function M.build_project()
    local command = internal._create_build_command(
        M.get_build_type()
    )
    internal._execute_command(command)
end

function M.run_build_target()
    local command = M.get_target_binary_path(M.get_build_target())
    internal._execute_command(command)
end

function M.make_clean()
    internal._execute_command("make clean")
end

return M

