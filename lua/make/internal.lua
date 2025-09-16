
local M = {}

function M._create_build_command(config)
    return string.format("make CONFIG=%s", config)
end

function M._execute_command(command)
    vim.cmd("botright split | terminal echo executing: " .. command .. "; " .. command)
end

return M

