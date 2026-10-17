local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Remotes = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Remotes"))

local player = Players.LocalPlayer
local fxRemote = Remotes.get("PressFx")

-- プレスの衝撃でカメラを揺らす(距離で減衰)
fxRemote.OnClientEvent:Connect(function(position: Vector3)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	if not (root and humanoid) then
		return
	end
	local strength = math.clamp(1 - (root.Position - position).Magnitude / 150, 0.1, 1) * 1.2
	local start = os.clock()
	local duration = 0.5
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local alpha = (os.clock() - start) / duration
		if alpha >= 1 or humanoid.Parent == nil then
			humanoid.CameraOffset = Vector3.zero
			conn:Disconnect()
			return
		end
		local amp = strength * (1 - alpha)
		humanoid.CameraOffset = Vector3.new((math.random() - 0.5) * amp, (math.random() - 0.5) * amp, 0)
	end)
end)
