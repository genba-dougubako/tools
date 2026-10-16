local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("CarCatalog"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local spawnRemote = Remotes.get("SpawnCar")
local buyRemote = Remotes.get("BuyCar")
local resetRemote = Remotes.get("ResetCar")
local notifyRemote = Remotes.get("Notify")

local function new(class: string, props: { [string]: any }, parent: Instance?)
	local inst = Instance.new(class)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local gui = new("ScreenGui", { Name = "CarCrashHUD", ResetOnSpawn = false }, player:WaitForChild("PlayerGui"))

local function text(props: { [string]: any }, parent: Instance)
	local base = {
		BackgroundTransparency = 1,
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		TextStrokeTransparency = 0.5,
	}
	for k, v in props do
		base[k] = v
	end
	return new("TextLabel", base, parent)
end

local function button(props: { [string]: any }, parent: Instance)
	local base = {
		BackgroundColor3 = Color3.fromRGB(40, 40, 48),
		Font = Enum.Font.GothamBold,
		TextColor3 = Color3.new(1, 1, 1),
		TextScaled = true,
		AutoButtonColor = true,
	}
	for k, v in props do
		base[k] = v
	end
	local b = new("TextButton", base, parent)
	new("UICorner", { CornerRadius = UDim.new(0, 8) }, b)
	return b
end

-- Cash
local cashLabel = text({
	Position = UDim2.new(0.5, -110, 0, 10),
	Size = UDim2.fromOffset(220, 36),
	TextColor3 = Color3.fromRGB(120, 255, 120),
}, gui)

-- Speed / health
local stats = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.fromOffset(300, 64),
	BackgroundColor3 = Color3.fromRGB(20, 20, 24),
	BackgroundTransparency = 0.3,
	Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, stats)
local speedLabel = text({ Size = UDim2.new(1, 0, 0, 34) }, stats)
local healthBack = new("Frame", {
	Position = UDim2.new(0, 10, 1, -20),
	Size = UDim2.new(1, -20, 0, 12),
	BackgroundColor3 = Color3.fromRGB(60, 0, 0),
	BorderSizePixel = 0,
}, stats)
local healthFill = new("Frame", {
	Size = UDim2.fromScale(1, 1),
	BackgroundColor3 = Color3.fromRGB(80, 220, 80),
	BorderSizePixel = 0,
}, healthBack)

-- Garage
local garageButton = button({
	Position = UDim2.new(0, 10, 0.5, -60),
	Size = UDim2.fromOffset(130, 40),
	Text = "GARAGE",
}, gui)
local resetButton = button({
	Position = UDim2.new(0, 10, 0.5, -14),
	Size = UDim2.fromOffset(130, 40),
	Text = "RESET (R)",
}, gui)

local panel = new("ScrollingFrame", {
	Position = UDim2.new(0, 150, 0.5, -60),
	Size = UDim2.fromOffset(320, 300),
	BackgroundColor3 = Color3.fromRGB(20, 20, 24),
	BackgroundTransparency = 0.1,
	BorderSizePixel = 0,
	CanvasSize = UDim2.new(),
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	Visible = false,
}, gui)
new("UICorner", { CornerRadius = UDim.new(0, 10) }, panel)
new("UIListLayout", { Padding = UDim.new(0, 6), SortOrder = Enum.SortOrder.LayoutOrder }, panel)
new("UIPadding", { PaddingTop = UDim.new(0, 6), PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6) }, panel)

local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")

local function refreshGarage()
	for _, child in panel:GetChildren() do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end

	local owned = {}
	for id in string.gmatch(player:GetAttribute("Owned") or "", "[^,]+") do
		owned[id] = true
	end

	for i, def in Catalog.Cars do
		local row = new("Frame", {
			LayoutOrder = i,
			Size = UDim2.new(1, 0, 0, 48),
			BackgroundColor3 = Color3.fromRGB(40, 40, 48),
		}, panel)
		new("UICorner", { CornerRadius = UDim.new(0, 8) }, row)
		text({
			Position = UDim2.fromOffset(8, 4),
			Size = UDim2.new(0.55, 0, 1, -8),
			Text = def.Name,
			TextXAlignment = Enum.TextXAlignment.Left,
		}, row)

		local isOwned = owned[def.Id]
		local affordable = cash.Value >= def.Price
		local action = button({
			AnchorPoint = Vector2.new(1, 0.5),
			Position = UDim2.new(1, -6, 0.5, 0),
			Size = UDim2.new(0.38, 0, 1, -12),
			Text = isOwned and "SPAWN" or `BUY ${def.Price}`,
			BackgroundColor3 = isOwned and Color3.fromRGB(40, 120, 200)
				or (affordable and Color3.fromRGB(40, 160, 70) or Color3.fromRGB(110, 50, 50)),
		}, row)
		action.Activated:Connect(function()
			if isOwned then
				spawnRemote:FireServer(def.Id)
			else
				buyRemote:FireServer(def.Id)
			end
		end)
	end
end

garageButton.Activated:Connect(function()
	panel.Visible = not panel.Visible
end)
resetButton.Activated:Connect(function()
	resetRemote:FireServer()
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.R then
		resetRemote:FireServer()
	end
end)

player:GetAttributeChangedSignal("Owned"):Connect(refreshGarage)
cash.Changed:Connect(function()
	cashLabel.Text = `$ {cash.Value}`
	refreshGarage()
end)
cashLabel.Text = `$ {cash.Value}`
refreshGarage()

-- Notifications
notifyRemote.OnClientEvent:Connect(function(message: string)
	local toast = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, math.random(-60, 60), 0.3, 0),
		Size = UDim2.fromOffset(300, 40),
		Text = message,
		TextColor3 = Color3.fromRGB(255, 230, 80),
	}, gui)
	local tween = TweenService:Create(toast, TweenInfo.new(1.2), {
		Position = toast.Position - UDim2.fromOffset(0, 60),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	Debris:AddItem(toast, 1.3)
end)

-- Speed / health readout
RunService.RenderStepped:Connect(function()
	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local car = seat and seat:IsA("VehicleSeat") and seat.Parent
	local chassis = car and car:FindFirstChild("Chassis")
	stats.Visible = chassis ~= nil
	if not chassis then
		return
	end

	-- 1 stud ~ 0.28 m
	speedLabel.Text = `{math.floor(chassis.AssemblyLinearVelocity.Magnitude * 0.28 * 3.6)} km/h`
	local ratio = math.clamp((car:GetAttribute("Health") or 0) / (car:GetAttribute("MaxHealth") or 1), 0, 1)
	healthFill.Size = UDim2.fromScale(ratio, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(220 * (1 - ratio) + 40, 220 * ratio + 20, 40)
end)
