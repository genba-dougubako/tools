local Players = game:GetService("Players")

local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)

local CarService = require(script.Parent.CarService)
local DamageService = require(script.Parent.DamageService)
local DataService = require(script.Parent.DataService)
local MapBuilder = require(script.Parent.MapBuilder)

local notify = Remotes.get("Notify")

DamageService.setRewardHandler(function(userId, amount, label)
	local player = Players:GetPlayerByUserId(userId)
	amount = math.floor(amount)
	if player and amount >= 1 then
		DataService.addCash(player, amount)
		notify:FireClient(player, `{label} +${amount}`)
	end
end)

DataService.init()
CarService.init(DataService)
MapBuilder.build()
