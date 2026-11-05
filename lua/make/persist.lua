
---
--- The selected build type and target per project directory (cwd), kept between sessions
---

local M = {}

local function path()
    return vim.fs.joinpath(vim.fn.stdpath("state"), "make.nvim", "selections.json")
end

local function read_all()
    local file = io.open(path(), "r")
    if not file then
        return {}
    end
    local content = file:read("*a")
    file:close()
    local ok, data = pcall(vim.json.decode, content)
    return ok and type(data) == "table" and data or {}
end

--- The saved selection for a directory, nil when there is none
---@return { build_type: string?, build_target: string? }|nil
function M.load(dir)
    local entry = read_all()[dir]
    return type(entry) == "table" and entry or nil
end

---@param entry { build_type: string, build_target: string }
function M.save(dir, entry)
    local data = read_all()
    data[dir] = entry
    vim.fn.mkdir(vim.fs.dirname(path()), "p")
    local file = io.open(path(), "w")
    if not file then
        return
    end
    file:write(vim.json.encode(data))
    file:close()
end

return M
