local Players = game:GetService("Players")

local Remotes = require(game:GetService("ReplicatedStorage").Shared.Remotes)

local CoinService = require(script.Parent.CoinService)
local DamageService = require(script.Parent.DamageService)
local DataService = require(script.Parent.DataService)
local EventService = require(script.Parent.EventService)
local LiftService = require(script.Parent.LiftService)
local MapBuilder = require(script.Parent.MapBuilder)
local PressService = require(script.Parent.PressService)
local RingService = require(script.Parent.RingService)
local ShowdownService = require(script.Parent.ShowdownService)
local VehicleService = require(script.Parent.VehicleService)

local notify = Remotes.get("Notify")

DamageService.setRewardHandler(function(userId, amount, label)
	local player = Players:GetPlayerByUserId(userId)
	amount = math.floor(amount)
	if player and amount >= 1 then
		DataService.addCash(player, amount)
		notify:FireClient(player, `{label} +${amount}`)
	end
end)

-- 機能を足すときは、ここに init を1行足す(各機能は EventService に統計を送ればイベントに参加できる)
DataService.init()
CoinService.init()
EventService.init()
VehicleService.init(DataService)
MapBuilder.build()
PressService.init(VehicleService)
RingService.init(VehicleService)
LiftService.init(VehicleService)
ShowdownService.init()
