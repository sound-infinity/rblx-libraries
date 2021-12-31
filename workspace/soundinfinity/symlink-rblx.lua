repeat
	game:GetService("RunService").Heartbeat:Wait()
until import ~= nil

local metatables = nil

local function log_info(...)
	print("symlink:", ...)
end

local function isKeyLinked(key, reference_table)
	for _, unlinked in next, reference_table.unlinkedKeys do
		if key == unlinked then
			return false
		end
	end
	return true
end

local function symlink_service_start(env)
	---@type WriteableMetatable
	local mt = metatables:open(game, "w")

	log_info("modifying game metatable...")
	mt:bind("__index", function(object, key)
		for _, properties in next, env.__SYMLINK_LINKED_OBJECTS do
			if object == properties.object then
				if isKeyLinked(key, properties.__index) then
					return properties.target[key]
				end
			end
		end
	end)
	mt:addNamecallListener("FireServer", function(object, namecall, ...)
		if object.ClassName == "RemoteEvent" or object.ClassName == "RemoteFunction" then
			print(object, namecall, ...)
		end
		-- for _, properties in next, env.__SYMLINK_LINKED_OBJECTS do
		-- 	if object == properties.object then
		-- 	end
		-- end
	end)
end

local function symlink_service_execute(callback, ...)
	if type(callback) == "function" then
		local success, message = pcall(callback, ...)
		if not success then
			log_info("error:", message)
		end
	end
end

local function symlink_service_access(callback)
	local env = getfenv(0)
	if not env.__SYMLINK_SERVICE_RUNNING then
		env.__SYMLINK_SERVICE_RUNNING = true
		env.__SYMLINK_LINKED_OBJECTS = {}
		symlink_service_start(env)
	end
	symlink_service_execute(callback, env)
end

local function symlink_service_link(object, target)
	symlink_service_access(function(env)
		table.insert(env.__SYMLINK_LINKED_OBJECTS, {
			object = object,
			target = target,
			__index = {
				unlinkedKeys = {
					"Name",
					"Parent",
				},
			},
		})
	end)
end

local function symlink(object, target)
	--#region arguments
	assert(object, "object not defined")
	assert(target, "target not defined")
	assert(object.Parent, "object does not have a parent")
	symlink_service_link(object, target)
end

-- todo: fix below
return function(import)
	metatables = import("soundinfinity/metatable-modifier.lua")

	local remotes = Instance.new("Folder")
	remotes.Name = "__REMOTES"
	remotes.Parent = workspace

	symlink(remotes, workspace.__THINGS.__REMOTES)
end
