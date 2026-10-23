local Players = game:GetService("Players")

local CoinService = {}

local function setup(player: Player)
	local stats = player:WaitForChild("leaderstats", 30)
	if stats and not stats:FindFirstChild("Coins") then
		local coins = Instance.new("IntValue")
		coins.Name = "Coins"
		coins.Parent = stats
	end
end

function CoinService.init()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(setup, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(setup, player)
	end
end

function CoinService.add(player: Player, amount: number)
	local stats = player:FindFirstChild("leaderstats")
	local coins = stats and stats:FindFirstChild("Coins")
	if coins then
		coins.Value += amount
	end
end

return CoinService
