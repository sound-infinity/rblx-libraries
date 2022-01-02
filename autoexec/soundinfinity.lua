---@author:  2021-12-31 14:28:18
--- helps to import a file from the workspace folder.
---@param path string
---@param supress_warnings boolean
local function import(path, supress_warnings)
	local function _warn(...)
		if supress_warnings ~= true then
			warn("import: warning:", ...)
		end
	end

	if isfile(path) then
		local contents = readfile(path)
		local retvalue = loadstring(contents)()
		if type(retvalue) ~= "table" then
			_warn("requested path did not return table.")
		end
		return retvalue
	else
		_warn("requested path is not a file.")
	end
end

if type(getgenv) == "function" then
	getgenv()["import"] = import
end

local function loadScript(name)
	local _script = import(("soundinfinity/%s.lua"):format(name), true)
	if type(_script) == "function" then
		_script(import)
	end
end

-- loadScript("symlink-rblx")

-- print(readfile("symlink-rblx.metatable-modifier.lua"))
