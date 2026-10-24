-- 右上の角の地図(真上から見た図。上が -Z 方向)。
-- 道路・プレス機・リング・プレイヤーを表示する。範囲は Config.MinimapCenter / MinimapRange。
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local StarterGui = game:GetService("StarterGui")
local UserInputService = game:GetService("UserInputService")

local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

local player = Players.LocalPlayer
local center = Config.MinimapCenter
local range = Config.MinimapRange

if Config.HidePlayerList then
	-- 標準のプレイヤー一覧が右上を占めるので隠す(所持金・コインは自前の表示で見える)
	task.spawn(function()
		for _ = 1, 10 do
			if pcall(StarterGui.SetCoreGuiEnabled, StarterGui, Enum.CoreGuiType.PlayerList, false) then
				return
			end
			task.wait(1)
		end
	end)
end

local size = UserInputService.TouchEnabled and 130 or 190

local gui = Instance.new("ScreenGui")
gui.Name = "Minimap"
gui.ResetOnSpawn = false
gui.Parent = player:WaitForChild("PlayerGui")

local map = Instance.new("Frame")
map.Name = "Map"
map.AnchorPoint = Vector2.new(1, 0)
map.Position = UDim2.new(1, -6, 0, 6) -- 右上の角
map.Size = UDim2.fromOffset(size, size)
map.BackgroundColor3 = Color3.fromRGB(60, 95, 55)
map.BackgroundTransparency = 0.2
map.ClipsDescendants = true
map.Parent = gui
local mapCorner = Instance.new("UICorner")
mapCorner.CornerRadius = UDim.new(0, 10)
mapCorner.Parent = map
local stroke = Instance.new("UIStroke")
stroke.Color = Color3.new(1, 1, 1)
stroke.Transparency = 0.4
stroke.Thickness = 2
stroke.Parent = map

local function toMap(position: Vector3): UDim2
	return UDim2.fromScale((position.X - center.X) / (2 * range) + 0.5, (position.Z - center.Z) / (2 * range) + 0.5)
end

local function rect(part: BasePart, color: Color3, z: number)
	local f = Instance.new("Frame")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = toMap(part.Position)
	f.Size = UDim2.fromScale(part.Size.X / (2 * range), part.Size.Z / (2 * range))
	f.Rotation = -math.deg(select(2, part.CFrame:ToEulerAnglesYXZ()))
	f.BackgroundColor3 = color
	f.BorderSizePixel = 0
	f.ZIndex = z
	f.Parent = map
	return f
end

local function dot(position: Vector3, color: Color3, px: number, label: string?, z: number)
	local f = Instance.new("TextLabel")
	f.AnchorPoint = Vector2.new(0.5, 0.5)
	f.Position = toMap(position)
	f.Size = UDim2.fromOffset(px, px)
	f.BackgroundColor3 = color
	f.Text = label or ""
	f.TextScaled = true
	f.Font = Enum.Font.GothamBold
	f.TextColor3 = Color3.new(0, 0, 0)
	f.ZIndex = z
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(1, 0)
	c.Parent = f
	f.Parent = map
	return f
end

-- 動かない目印(道路・プレス機・リング)は一度だけ描く
local ringDots = {}
task.spawn(function()
	local mapFolder = workspace:WaitForChild("Map", 15)
	local road = mapFolder and mapFolder:FindFirstChild("Road")
	if road then
		rect(road, Color3.fromRGB(70, 70, 75), 1)
	end
	local press = workspace:WaitForChild("CarPress", 15)
	local floor = press and press:FindFirstChild("Floor")
	if floor then
		local f = rect(floor, Color3.fromRGB(230, 150, 20), 2)
		local label = Instance.new("TextLabel")
		label.Size = UDim2.fromScale(1, 1)
		label.BackgroundTransparency = 1
		label.Text = "P"
		label.TextScaled = true
		label.Font = Enum.Font.GothamBlack
		label.TextColor3 = Color3.new(0, 0, 0)
		label.ZIndex = 3
		label.Parent = f
	end
	local rings = workspace:WaitForChild("SkyRings", 15)
	if rings then
		for _, ring in rings:GetChildren() do
			local index = tonumber(ring.Name:match("%d+"))
			if index then
				ringDots[index] = dot(ring:GetPivot().Position, Color3.fromRGB(80, 220, 255), 9, nil, 3)
			end
		end
	end
end)

-- 自分(矢印)と他のプレイヤー(点)
local me = Instance.new("TextLabel")
me.AnchorPoint = Vector2.new(0.5, 0.5)
me.Size = UDim2.fromOffset(16, 16)
me.BackgroundTransparency = 1
me.Text = "▲"
me.TextScaled = true
me.TextColor3 = Color3.new(1, 1, 1)
me.TextStrokeTransparency = 0
me.ZIndex = 6
me.Parent = map

local others = {} -- [Player] = TextLabel

local elapsed = 0
RunService.RenderStepped:Connect(function(dt)
	elapsed += dt
	if elapsed < 0.05 then
		return
	end
	elapsed = 0

	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if root then
		me.Visible = true
		me.Position = toMap(root.Position)
		local look = root.CFrame.LookVector
		me.Rotation = math.deg(math.atan2(look.X, -look.Z))
	else
		me.Visible = false
	end

	-- 次に通るリングを大きく
	local nextRing = player:GetAttribute("RingNext") or 1
	for index, d in ringDots do
		local isNext = index == nextRing
		d.Size = UDim2.fromOffset(isNext and 14 or 8, isNext and 14 or 8)
		d.BackgroundColor3 = isNext and Color3.fromRGB(120, 255, 120) or Color3.fromRGB(80, 220, 255)
		d.Text = isNext and tostring(index) or ""
	end

	for _, other in Players:GetPlayers() do
		if other ~= player then
			local otherRoot = other.Character and other.Character:FindFirstChild("HumanoidRootPart")
			local d = others[other]
			if otherRoot then
				if not d then
					d = dot(otherRoot.Position, Color3.fromRGB(255, 80, 80), 8, nil, 5)
					others[other] = d
				end
				d.Position = toMap(otherRoot.Position)
			elseif d then
				d:Destroy()
				others[other] = nil
			end
		end
	end
end)

Players.PlayerRemoving:Connect(function(other)
	if others[other] then
		others[other]:Destroy()
		others[other] = nil
	end
end)
