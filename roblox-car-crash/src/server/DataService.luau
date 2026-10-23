local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local Config = require(Shared.Config)
local Catalog = require(Shared.VehicleCatalog)

local DataService = {}

local store = DataStoreService:GetDataStore(Config.DataStoreName)
local profiles = {} -- [Player] = { Cash: number, Owned: { [carId]: true }, Loaded: boolean }

local function key(player: Player)
	return `u_{player.UserId}`
end

local function publish(player: Player)
	local profile = profiles[player]
	local ids = {}
	for id in profile.Owned do
		table.insert(ids, id)
	end
	table.sort(ids)
	player:SetAttribute("Owned", table.concat(ids, ","))
	player.leaderstats.Cash.Value = profile.Cash
end

local function save(player: Player)
	local profile = profiles[player]
	if not profile or not profile.Loaded then
		return
	end
	local ok, err = pcall(function()
		store:SetAsync(key(player), { Cash = profile.Cash, Owned = profile.Owned })
	end)
	if not ok then
		warn(`Save failed for {player.Name}: {err}`)
	end
end

local function onPlayerAdded(player: Player)
	local leaderstats = Instance.new("Folder")
	leaderstats.Name = "leaderstats"
	local cash = Instance.new("IntValue")
	cash.Name = "Cash"
	cash.Parent = leaderstats
	leaderstats.Parent = player

	local profile = { Cash = Config.StartCash, Owned = {}, Loaded = false }
	for _, id in Config.StartCars do
		profile.Owned[id] = true
	end

	local ok, data = pcall(function()
		return store:GetAsync(key(player))
	end)
	if ok then
		if data then
			profile.Cash = data.Cash or profile.Cash
			for id in data.Owned or {} do
				if Catalog.ById[id] then
					profile.Owned[id] = true
				end
			end
		end
		profile.Loaded = true
	else
		warn(`Load failed for {player.Name}, progress will not be saved: {data}`)
	end

	profiles[player] = profile
	publish(player)
end

function DataService.owns(player: Player, carId: string): boolean
	local profile = profiles[player]
	return profile ~= nil and profile.Owned[carId] == true
end

function DataService.addCash(player: Player, amount: number)
	local profile = profiles[player]
	if profile then
		profile.Cash += amount
		publish(player)
	end
end

function DataService.spend(player: Player, amount: number): boolean
	local profile = profiles[player]
	if profile and profile.Cash >= amount then
		profile.Cash -= amount
		publish(player)
		return true
	end
	return false
end

function DataService.grant(player: Player, carId: string)
	local profile = profiles[player]
	if profile then
		profile.Owned[carId] = true
		publish(player)
	end
end

function DataService.init()
	Players.PlayerAdded:Connect(onPlayerAdded)
	for _, player in Players:GetPlayers() do
		task.spawn(onPlayerAdded, player)
	end

	Players.PlayerRemoving:Connect(function(player)
		save(player)
		profiles[player] = nil
	end)

	game:BindToClose(function()
		for player in profiles do
			save(player)
		end
	end)

	task.spawn(function()
		while true do
			task.wait(Config.AutoSaveInterval)
			for player in profiles do
				save(player)
			end
		end
	end)
end

return DataService
