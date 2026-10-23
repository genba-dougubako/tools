local Players = game:GetService("Players")

local Shared = game:GetService("ReplicatedStorage").Shared
local EventCatalog = require(Shared.EventCatalog)
local Remotes = require(Shared.Remotes)

local EventService = {}

local stats = {} -- [Player] = { [stat]: number }
local done = {} -- [Player] = { [eventId]: true }

local notify = Remotes.get("Notify")

local function setup(player: Player)
	stats[player] = stats[player] or {}
	done[player] = done[player] or {}
end

function EventService.isDone(player: Player, eventId: string): boolean
	return done[player] ~= nil and done[player][eventId] == true
end

local function check(player: Player)
	for _, event in EventCatalog.Events do
		if event.Status == "active" and not done[player][event.Id] then
			local clear = #event.Requirements > 0
			for _, req in event.Requirements do
				if (stats[player][req.Stat] or 0) < req.Target then
					clear = false
					break
				end
			end
			if clear then
				done[player][event.Id] = true
				player:SetAttribute(`Done_{event.Id}`, true)
				notify:FireClient(player, `EVENT CLEAR: {event.Name}! New items can be bought.`)
			end
		end
	end
end

-- 各機能から統計を加算する(例: プレス成功、リング通過、コース完走)
function EventService.add(player: Player, stat: string, amount: number?)
	if not stats[player] then
		return
	end
	local value = (stats[player][stat] or 0) + (amount or 1)
	stats[player][stat] = value
	player:SetAttribute(`Stat_{stat}`, value)
	check(player)
end

function EventService.init()
	Players.PlayerAdded:Connect(setup)
	for _, player in Players:GetPlayers() do
		setup(player)
	end
	Players.PlayerRemoving:Connect(function(player)
		stats[player] = nil
		done[player] = nil
	end)
end

return EventService
