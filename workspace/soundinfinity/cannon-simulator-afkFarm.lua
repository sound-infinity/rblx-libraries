local tinsert = table.insert

local function getAreaListAsArray()
	local container = workspace.__AREAS
	local list = {}
	for _, area in next, container:GetChildren() do
		list[#list + 1] = area
	end
	return list
end

local function getAreaListAsTable(_area_name)
	local areaListArray = getAreaListAsArray()
	local list = {}
	for _, area in next, areaListArray do
		list[area.Name] = area
	end
	return list
end

local function getArea(name)
	return workspace.__AREAS:FindFirstChild(name)
end

local function getBlockListFromArea(name)
	return getArea(name):GetChildren()
end

local Block = { _registered = {} }
function Block:new(block)
	if self._registered[block] then
		return self._registered[block]
	end
	local obj = { object = block, cached = {} }
	setmetatable(obj, Block)
	Block.__index = Block
	self._registered[block] = obj
	return obj
end

function Block:firstChild()
	local firstChild = self.cached.firstChild or self.object:GetChildren()[1]
	self.cached.firstChild = firstChild
	return firstChild
end

function Block:health()
	local health = self:firstChild():FindFirstChild("Health")
	self.cached.health = health
	if health then
		return health.Value
	end
	return -1
end

function Block:maxHealth()
	local maxHealth = self:firstChild():FindFirstChild("MaxHealth")
	self.cached.maxhealth = maxHealth
	if maxHealth then
		return maxHealth.Value
	end
	return -1
end

function Block:position()
	local firstChild = self:firstChild()
	if firstChild then
		local position = self.cached.position or firstChild.Position
		self.cached.position = position
		return position
	end
end

local function getWeakestBlockFromList(blockList)
	-- local userData = game.ReplicatedStorage.__REMOTES.__GetData:InvokeServer()
	-- local damage = userData.Cannon_Damage

	local weakest, weakestValue
	for _, blockObject in next, blockList do
		local block = Block:new(blockObject)
		if block:health() > 0 then
			if weakestValue ~= nil then
				if block:health() <= weakestValue then
					weakest = block
					weakestValue = block:health()
				end
			else
				weakest = block
				weakestValue = block:health()
			end
		end
	end
	return weakest
end

local LocalPlayer = game.Players.LocalPlayer
local hooked = {}
function teleport()
	local character = LocalPlayer.Character
	local joined = {}
	-- for _, v in next, getBlockListFromArea("Spawn") do
	-- 	tinsert(joined, v)
	-- end
	for _, v in next, getBlockListFromArea("Beach") do
		tinsert(joined, v)
	end
	local block = getWeakestBlockFromList(joined)
	character:MoveTo(block:position())
	if not hooked[block:firstChild()] then
		hooked[block:firstChild()] = block:firstChild():GetPropertyChangedSignal("Position"):Connect(teleport)
	end
end

LocalPlayer.leaderstats.Coins:GetPropertyChangedSignal("Value"):Connect(teleport)
teleport()
