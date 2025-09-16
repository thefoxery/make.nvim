
local internal = require("make.internal")
local state = require("make.state")

local M = {}

local MAKEFILE_NAME = "Makefile"

local default_opts = {
    build_types = { "debug", "release" },
    build_type = "debug",
}

local resolve = function(opt)
    if type(opt) == "function" then
        return opt()
    else
        return opt
    end
end

function M.setup(user_opts)
    state.build_types = resolve(user_opts.build_types) or default_opts.build_types
    state.build_type = resolve(user_opts.default_build_type) or default_opts.build_type
    state.build_target = ""

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
end

function M.get_build_type()
    return state.build_type
end

function M.get_build_types()
    return state.build_types
end

function M.set_build_target(build_target)
    state.build_target = build_target
end

function M.get_build_target()
    return state.build_target
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

