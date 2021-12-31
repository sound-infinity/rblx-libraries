---@author:  2021-12-31 14:28:30 SoundInfinity
local function getEnvironment()
	local env
	env = (getgenv or getfenv or warn)(0) or {}
	if not env.script then
		env.script = {}
	end
	return env
end

local METATABLES_GLOBAL = "__METATABLES__"
---@class Metatables
local metatables = {
	_opened = {},
	modes = {
		---@param lib Metatables
		["r"] = function(lib, object)
			return lib:new_readable_mt(object)
		end,
		["w"] = function(lib, object)
			return lib:new_writeable_mt(object)
		end,
		read = "r",
		write = "w",
	},
}

local tinsert = table.insert
local tremove = table.remove
---@class BaseMetatable
---@field public object userdata
---@field public parent BaseMetatable
---@field public metatable table
local BaseMetatable = {}
function BaseMetatable:access(method)
	return rawget(self._backupList, method) or rawget(self.metatable, method)
end

function BaseMetatable:inBackup(method)
	return rawget(self._backupList, method) ~= nil and true
end

---@return BaseMetatable
function metatables:new_metatable(object)
	---@type BaseMetatable
	local this = {}
	this._backupList = {}
	this.object = object
	this.parent = self
	this.metatable = getrawmetatable(object)
	-- todo: this.namecallService
	setmetatable(this, BaseMetatable)
	BaseMetatable.__index = BaseMetatable
	return this
end

function metatables:new_readable_mt(object)
	---@class ReadableMetatable : BaseMetatable
	local this = self:new_metatable(object)
	return this
end

--#region WriteableMetatable
---@class WriteableMetatable: BaseMetatable
---@field public onclose fun(): nil
---@field public _namecallListeners table<string, fun(): void>
local WriteableMetatable = setmetatable(
	{ _namecallListeners = {}, _namecallHooked = false },
	{ __index = BaseMetatable }
)
function WriteableMetatable:_wrap(target, oncall)
	assert(type(target) == "function", "target is not a function.")
	assert(type(oncall) == "function", "oncall is not a function.")
	return self.parent:_newcclosure(function(...)
		local response = oncall(...)
		if response ~= nil then
			return response
		else
			return target(...)
		end
	end)
end

function WriteableMetatable:_backup(method)
	if not self:inBackup(method) then
		rawset(self._backupList, method, self:access(method))
	end
end

function WriteableMetatable:_replace(method, oncall)
	rawset(self.metatable, method, self:_wrap(self:access(method), oncall))
end

--#region __namecall
function WriteableMetatable:_hookNamecall()
	if self._namecallHooked then
		return
	end
	--#region
	local RunService = game:GetService("RunService")
	self:bind("__namecall", function(object, ...)
		if object == RunService then
			return
		end
		local namecall
		do
			if getnamecallmethod ~= nil then
				namecall = getnamecallmethod()
			end
		end
		if namecall ~= nil then
			for _, data in next, self._namecallListeners do
				if data.key == "*" or data.key == namecall then
					pcall(function(...)
						local preventDefault = data.listener(object, namecall, ...)
						if preventDefault ~= nil then
							return preventDefault
						end
					end, ...)
				end
			end
			-- else
			-- 	self:unbind("__namecall")
		end
	end)
	--#endregion
	self._namecallHooked = true
end

function WriteableMetatable:addNamecallListener(key, listener)
	assert(key, "key is not defined.")
	assert(type(listener) == "function", "listener is not a function.")
	self:_hookNamecall()
	tinsert(self._namecallListeners, { key = key, listener = listener })
	return {
		disconnect = function()
			for index, data in next, self._namecallListeners do
				if data.key == key and data.listener == listener then
					tremove(index)
				end
			end
		end,
	}
end
--#endregion

function WriteableMetatable:bind(method, oncall)
	assert(type(oncall), "oncall is not a function.")
	self.parent:unlock(self.metatable)
	self:_backup(method)
	self:_replace(method, oncall)
	self.parent:lock(self.metatable)
end

function WriteableMetatable:unbind(method)
	self.parent:unlock(self.metatable)
	rawset(self.metatable, method, self:access(method))
	self.parent:lock(self.metatable)
end

function WriteableMetatable:close()
	local onclose = rawget(self, "onclose")
	for method in next, self._backupList do
		self:unbind(method)
	end
	if type(onclose) == "function" then
		onclose()
	end
end
---#endregion

---@return WriteableMetatable
function metatables:new_writeable_mt(object)
	--#region check if opened
	local openedInstance = rawget(self._opened, object)
	if openedInstance then
		return openedInstance
	end
	--#endregion
	---@type WriteableMetatable
	local o = self:new_metatable(object)
	rawset(self._opened, object, o)
	setmetatable(o, WriteableMetatable)
	WriteableMetatable.__index = WriteableMetatable
	o.onclose = function()
		rawset(self._opened, object, nil)
	end
	return o
end

--#region readonly-handler
function metatables:isLocked(mt)
	return isreadonly(mt)
end

function metatables:unlock(mt)
	if self:isLocked(mt) then
		setreadonly(mt, false)
	end
end

function metatables:lock(mt)
	if not metatables:isLocked(mt) then
		setreadonly(mt, true)
	end
end
--#endregion

function metatables:_newcclosure(_function)
	return newcclosure(_function) or function()
		return _function
	end
end

--- func desc
---@param object userdata
---@param mode string w (write) | r (read)
function metatables:open(object, mode)
	assert(self.modes[mode], "mode is not defined.")
	assert(self.modes[mode], "mode is not valid.")
	return self.modes[mode](self, object)
end

--#region allows unbinding
if getEnvironment()[METATABLES_GLOBAL] then
	metatables = getEnvironment()[METATABLES_GLOBAL]
else
	getEnvironment()[METATABLES_GLOBAL] = metatables
end
--#endregion

function metatables:Test()
	print("testing: binding test")
	---@type WriteableMetatable
	local obj = game
	local mt = self:open(obj, "w")
	local example_key = "roblox-fun"
	mt:bind("__index", function(_, key)
		if key == example_key then
			return true
		end
	end)
	local function check_return()
		local success = pcall(function()
			local retval = obj[example_key]
			print(("testing: retvalue (%s) ; rettype (%s)"):format(tostring(retval), type(retval)))
			print("testing: passed!")
		end)
		return success
	end
	if not check_return() then
		print("testing: failed!")
	end

	print("testing: metatable:close()")
	mt:close()
	if not check_return() then
		print("testing: passed!")
	end
end

return metatables
