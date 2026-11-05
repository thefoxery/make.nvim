
local PLUGIN_NAME = "make.nvim"

local internal = require("make.internal")
local state = require("make.state")
local persist = require("make.persist")

local M = {}

local default_opts = {
    build_types = { "debug", "release" },
    build_type = "debug",
    persist = true,
    make = {
        targets_target_name = "targets",
    },
}

-- the selection saved for the current directory, the defaults when there is none
local function restore()
    local saved = state.persist and persist.load(vim.fn.getcwd()) or {}
    state.build_type = vim.tbl_contains(state.build_types, saved.build_type) and saved.build_type or state.default_build_type
    state.build_target = type(saved.build_target) == "string" and saved.build_target or ""
end

local function save()
    if state.persist then
        persist.save(vim.fn.getcwd(), { build_type = state.build_type, build_target = state.build_target })
    end
end

function M.setup(user_opts)
    user_opts = user_opts or {}
    user_opts.make = user_opts.make or {}

    state.build_types = internal._resolve(user_opts.build_types) or default_opts.build_types
    state.default_build_type = internal._resolve(user_opts.default_build_type) or default_opts.build_type
    state.build_type = state.default_build_type
    state.persist = internal._resolve(user_opts.persist)
    if state.persist == nil then
        state.persist = default_opts.persist
    end
    state.make = state.make or {}
    state.make.targets_target_name = internal._resolve(user_opts.make.targets_target_name) or default_opts.make.targets_target_name
    state.build_target = ""

    vim.api.nvim_create_user_command("MakeBuild", function()
        M.build_project()
    end, {})

    restore()
    vim.api.nvim_create_autocmd("DirChanged", {
        group = vim.api.nvim_create_augroup("make_nvim_persist", { clear = true }),
        callback = restore,
    })

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
    save()
end

function M.get_build_targets()
    if state.make == nil or state.make.targets_target_name == nil then
        vim.notify(string.format("[%s] Trying to get build targets but the specificed target name '%s' is invalid", PLUGIN_NAME), vim.log.levels.ERROR)
        return {}
    end
    local output = vim.fn.systemlist(string.format("make %s", state.make.targets_target_name))

    local no_rule = false
    local exit_code = vim.v.shell_error
    if exit_code ~= 0 then
        for _, line in ipairs(output) do
            if line:match("No rule to make target") then
                no_rule = true
                break
            end
        end
        if no_rule then
            print(string.format("[%s] Plugin needs a build target named '%s' to get a list of available build targets", PLUGIN_NAME, state.make.targets_target_name))
        else
            print(string.format("make failed with exit code '%d'", exit_code))
            print(vim.inspect(output))
        end
    end

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
    save()
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

