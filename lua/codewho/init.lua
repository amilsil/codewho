print("Codewho: loading")

local M = {}
M.codeowners_table = {}
M.codeowners_exists = true

local read_codeowners_file = function()
  if (M.codeowners_exists == false) then
    return "noowner"
  end

  local working_dir = vim.fn.getcwd()
  local github_dir = working_dir .. "/.github"
  local codeowners_file = github_dir .. "/CODEOWNERS"
  local handle = io.open(codeowners_file, "r")

  if (handle ~= nil) then
    local result = handle:read("*a")
    handle:close()
    return result
  else
    M.codeowners_exists = false
    return ""
  end
end

local parse_codeowners = function()
  local codeowners_file = read_codeowners_file()
  local codeowners = {}
  for line in codeowners_file:gmatch("[^\r\n]+") do
    local path, owner = line:match("^(%S+)%s+(.+)")
    if path and owner then
      codeowners[path] = owner
    end
  end
  return codeowners
end

local delete_last_path_segment = function(path)
  local last_slash_index = path:find("/[^/]*$")
  if last_slash_index then
    return path:sub(1, last_slash_index - 1)
  else
    return nil
  end
end

local find_owner_of_file = function(buffer_name)
  local codeowners = parse_codeowners()
  local path = buffer_name

  while (path ~= nil) do
    local owner = codeowners[path] or codeowners[path .. "/"] or codeowners[path .. "/*"]
    if owner then
      return owner
    end

    path = delete_last_path_segment(path)
  end

  if (codeowners["*"] ~= nil) then
    return codeowners["*"]
  end

  return "noowner"
end

M.codewho = function()
  if (M.codeowners_exists == false) then
    return "noowner"
  end

  local buffer_name = vim.fn.expand("%")

  if (M.codeowners_table[buffer_name] == nil) then
    local owner = find_owner_of_file(buffer_name)
    M.codeowners_table[buffer_name] = owner
  end

  local owner = M.codeowners_table[buffer_name]
  return owner
end

return M
