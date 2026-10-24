local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Catalog = require(Shared:WaitForChild("VehicleCatalog"))
local EventCatalog = require(Shared:WaitForChild("EventCatalog"))
local Paints = require(Shared:WaitForChild("Paints"))
local Config = require(Shared:WaitForChild("Config"))
local Remotes = require(Shared:WaitForChild("Remotes"))

local player = Players.LocalPlayer
local spawnRemote = Remotes.get("SpawnCar")
local buyRemote = Remotes.get("BuyCar")
local resetRemote = Remotes.get("ResetCar")
local paintRemote = Remotes.get("SetPaint")
local notifyRemote = Remotes.get("Notify")

-- ガレージのカテゴリ(国産車 / 海外車 / 飛行機・ヘリ)
local CATEGORIES = {
	{ Id = "jp", Label = "国産車", Match = function(def)
		return def.Kind == "car" and def.Origin == "jp"
	end },
	{ Id = "os", Label = "海外車", Match = function(def)
		return def.Kind == "car" and def.Origin == "os"
	end },
	{ Id = "air", Label = "飛行機・ヘリ", Match = function(def)
		return def.Kind ~= "car"
	end },
}
local KIND_LABEL = { plane = "飛行機", heli = "ヘリ" }
local category = "jp"

local PANEL_BG = Color3.fromRGB(22, 22, 28)
local CARD_BG = Color3.fromRGB(42, 42, 52)
local BLUE = Color3.fromRGB(40, 120, 200)

local function new(class: string, props: { [string]: any }, parent: Instance?)
	local inst = Instance.new(class)
	for k, v in props do
		inst[k] = v
	end
	inst.Parent = parent
	return inst
end

local function corner(parent: Instance, radius: number)
	new("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

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
	corner(b, 8)
	return b
end

local function formatMoney(n: number): string
	local s = tostring(n)
	repeat
		local changed
		s, changed = s:gsub("^(%d+)(%d%d%d)", "%1,%2")
	until changed == 0
	return "$" .. s
end

local gui = new("ScreenGui", { Name = "CarCrashHUD", ResetOnSpawn = false, IgnoreGuiInset = false }, player:WaitForChild("PlayerGui"))

-- ===== 入ったときのタイトル表示(3 秒で消える) =====
do
	local title = text({
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.4),
		Size = UDim2.fromScale(0.6, 0.14),
		Text = Config.GameTitle,
		Font = Enum.Font.GothamBlack,
		TextStrokeTransparency = 0,
		TextStrokeColor3 = Color3.fromRGB(20, 33, 61),
	}, gui)
	local subtitle = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.fromScale(0.5, 0.48),
		Size = UDim2.fromScale(0.4, 0.06),
		Text = Config.GameSubtitle,
		TextColor3 = Color3.fromRGB(255, 210, 58),
		TextStrokeTransparency = 0,
	}, gui)
	task.delay(3, function()
		for _, label in { title, subtitle } do
			TweenService:Create(label, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
			Debris:AddItem(label, 1)
		end
	end)
end

-- ===== 上部: 現金 / コイン / 対決戦 / リング =====
local cashLabel = text({ Position = UDim2.new(0.5, -110, 0, 6), Size = UDim2.fromOffset(220, 32), TextColor3 = Color3.fromRGB(120, 255, 120) }, gui)
local coinsLabel = text({ Position = UDim2.new(0.5, -110, 0, 40), Size = UDim2.fromOffset(220, 26), TextColor3 = Color3.fromRGB(255, 220, 60) }, gui)
local showdownLabel = text({ Position = UDim2.new(0.5, -170, 0, 68), Size = UDim2.fromOffset(340, 22), TextColor3 = Color3.fromRGB(255, 120, 80) }, gui)
local ringLabel = text({ Position = UDim2.new(0.5, -110, 0, 92), Size = UDim2.fromOffset(220, 22), TextColor3 = Color3.fromRGB(120, 220, 255), Visible = false }, gui)

-- ===== 下部: 速度 / 高度 / 体力 =====
local stats = new("Frame", {
	AnchorPoint = Vector2.new(0.5, 1),
	Position = UDim2.new(0.5, 0, 1, -20),
	Size = UDim2.fromOffset(280, 60),
	BackgroundColor3 = PANEL_BG,
	BackgroundTransparency = 0.3,
	Visible = false,
}, gui)
corner(stats, 10)
local speedLabel = text({ Size = UDim2.new(1, 0, 0, 32) }, stats)
local healthBack = new("Frame", { Position = UDim2.new(0, 10, 1, -18), Size = UDim2.new(1, -20, 0, 10), BackgroundColor3 = Color3.fromRGB(60, 0, 0), BorderSizePixel = 0 }, stats)
local healthFill = new("Frame", { Size = UDim2.fromScale(1, 1), BackgroundColor3 = Color3.fromRGB(80, 220, 80), BorderSizePixel = 0 }, healthBack)

-- ===== 左: メニュー =====
local menu = new("Frame", { AnchorPoint = Vector2.new(0, 0.5), Position = UDim2.new(0, 10, 0.45, 0), Size = UDim2.fromOffset(120, 140), BackgroundTransparency = 1 }, gui)
new("UIListLayout", { Padding = UDim.new(0, 6) }, menu)
local garageButton = button({ Size = UDim2.new(1, 0, 0, 42), Text = "ガレージ", BackgroundColor3 = BLUE }, menu)
local eventsButton = button({ Size = UDim2.new(1, 0, 0, 42), Text = "イベント" }, menu)
local resetButton = button({ Size = UDim2.new(1, 0, 0, 42), Text = "リセット" }, menu)

-- ===== ウィンドウ(画面中央、画面サイズに合わせて縮む) =====
local function window(title: string)
	local frame = new("Frame", {
		AnchorPoint = Vector2.new(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.52),
		Size = UDim2.fromScale(0.72, 0.78),
		BackgroundColor3 = PANEL_BG,
		BackgroundTransparency = 0.05,
		Visible = false,
	}, gui)
	corner(frame, 14)
	new("UISizeConstraint", { MaxSize = Vector2.new(640, 500), MinSize = Vector2.new(280, 260) }, frame)
	text({ Position = UDim2.fromOffset(14, 8), Size = UDim2.new(1, -70, 0, 30), Text = title, TextXAlignment = Enum.TextXAlignment.Left }, frame)
	local close = button({ AnchorPoint = Vector2.new(1, 0), Position = UDim2.new(1, -8, 0, 8), Size = UDim2.fromOffset(36, 32), Text = "✕" }, frame)
	close.Activated:Connect(function()
		frame.Visible = false
	end)
	return frame
end

local garage = window("ガレージ")
local eventsWindow = window("イベント")

-- カテゴリのタブ
local tabs = new("Frame", { Position = UDim2.fromOffset(10, 46), Size = UDim2.new(1, -20, 0, 40), BackgroundTransparency = 1 }, garage)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6) }, tabs)

-- 色選び
local paintRow = new("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 92),
	Size = UDim2.new(1, -20, 0, 40),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	ScrollingDirection = Enum.ScrollingDirection.X,
	AutomaticCanvasSize = Enum.AutomaticSize.X,
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 4,
}, garage)
new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 6), VerticalAlignment = Enum.VerticalAlignment.Center }, paintRow)

-- 乗り物カードの一覧
local grid = new("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 140),
	Size = UDim2.new(1, -20, 1, -150),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, garage)
local gridLayout = new("UIGridLayout", { CellPadding = UDim2.fromOffset(8, 8), CellSize = UDim2.new(0.5, -4, 0, 140), SortOrder = Enum.SortOrder.LayoutOrder }, grid)
grid:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
	-- 広い画面は3列、狭い画面(携帯)は2列
	local columns = grid.AbsoluteSize.X > 520 and 3 or 2
	gridLayout.CellSize = UDim2.new(1 / columns, -8 * (columns - 1) / columns, 0, 140)
end)

local eventsList = new("ScrollingFrame", {
	Position = UDim2.fromOffset(10, 46),
	Size = UDim2.new(1, -20, 1, -56),
	BackgroundTransparency = 1,
	BorderSizePixel = 0,
	AutomaticCanvasSize = Enum.AutomaticSize.Y,
	CanvasSize = UDim2.new(),
	ScrollBarThickness = 6,
}, eventsWindow)
new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder }, eventsList)

local cash = player:WaitForChild("leaderstats"):WaitForChild("Cash")

local function clear(container: Instance)
	for _, child in container:GetChildren() do
		if child:IsA("GuiObject") then
			child:Destroy()
		end
	end
end

local function ownedSet()
	local owned = {}
	for id in string.gmatch(player:GetAttribute("Owned") or "", "[^,]+") do
		owned[id] = true
	end
	return owned
end

local refreshGarage

local function refreshTabs()
	clear(tabs)
	for _, cat in CATEGORIES do
		local count = 0
		for _, def in Catalog.Vehicles do
			if cat.Match(def) then
				count += 1
			end
		end
		local tab = button({
			Size = UDim2.new(1 / #CATEGORIES, -4, 1, 0),
			Text = `{cat.Label} ({count})`,
			BackgroundColor3 = category == cat.Id and BLUE or Color3.fromRGB(50, 50, 60),
		}, tabs)
		tab.Activated:Connect(function()
			category = cat.Id
			grid.CanvasPosition = Vector2.zero
			refreshGarage()
		end)
	end
end

local function refreshPaint()
	clear(paintRow)
	text({ Size = UDim2.fromOffset(34, 30), Text = "色", LayoutOrder = -1 }, paintRow)
	local selected = player:GetAttribute("Paint") or 0
	for index = 0, #Paints do
		local swatch = button({
			LayoutOrder = index,
			Size = UDim2.fromOffset(index == 0 and 52 or 34, 34),
			Text = index == 0 and "標準" or "",
			BackgroundColor3 = index == 0 and Color3.fromRGB(70, 70, 80) or Paints[index].Color,
		}, paintRow)
		if index == selected then
			new("UIStroke", { Color = Color3.new(1, 1, 1), Thickness = 3, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }, swatch)
		end
		swatch.Activated:Connect(function()
			paintRemote:FireServer(index)
		end)
	end
end

-- 加速を ★1〜5 で表す(車と飛行機。ヘリは加速の値がないので出さない)
local function accelStars(accel: number?): string
	if not accel then
		return ""
	end
	local stars = math.clamp(math.floor((accel - 25) / 18) + 1, 1, 5)
	return "  加速 " .. string.rep("★", stars) .. string.rep("☆", 5 - stars)
end

local function card(def, order: number, owned)
	local frame = new("Frame", { LayoutOrder = order, BackgroundColor3 = CARD_BG }, grid)
	corner(frame, 10)
	local paint = player:GetAttribute("Paint") or 0
	local stripe = new("Frame", {
		Size = UDim2.new(1, 0, 0, 10),
		BackgroundColor3 = (owned[def.Id] and paint > 0) and Paints[paint].Color or def.Color,
		BorderSizePixel = 0,
	}, frame)
	corner(stripe, 10)

	text({ Position = UDim2.fromOffset(8, 14), Size = UDim2.new(1, -16, 0, 24), Text = def.Name, TextXAlignment = Enum.TextXAlignment.Left }, frame)

	local event = def.RequiresEvent and EventCatalog.ById[def.RequiresEvent]
	local unlocked = not def.RequiresEvent or player:GetAttribute(`Done_{def.RequiresEvent}`) == true
	local info
	if owned[def.Id] then
		info = "所持"
	elseif not unlocked and event then
		info = `🔒 {event.Name}`
	else
		info = formatMoney(def.Price)
	end
	if KIND_LABEL[def.Kind] then
		info = `{KIND_LABEL[def.Kind]}  ·  {info}`
	end
	text({
		Position = UDim2.fromOffset(8, 42),
		Size = UDim2.new(1, -16, 0, 20),
		Text = info,
		TextColor3 = Color3.fromRGB(180, 180, 190),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)

	-- 1 stud/s は約 1 km/h(1 stud ≒ 0.28 m)
	text({
		Position = UDim2.fromOffset(8, 64),
		Size = UDim2.new(1, -16, 0, 18),
		Text = `最高 {math.floor(def.MaxSpeed * 0.28 * 3.6)} km/h{accelStars(def.Accel)}`,
		TextColor3 = Color3.fromRGB(255, 210, 120),
		TextXAlignment = Enum.TextXAlignment.Left,
	}, frame)

	local label, color
	if owned[def.Id] then
		label, color = "乗る", BLUE
	elseif not unlocked then
		label, color = "ロック中", Color3.fromRGB(80, 80, 88)
	elseif cash.Value >= def.Price then
		label, color = "買う", Color3.fromRGB(40, 160, 70)
	else
		label, color = "お金が足りない", Color3.fromRGB(110, 50, 50)
	end
	local action = button({
		AnchorPoint = Vector2.new(0.5, 1),
		Position = UDim2.new(0.5, 0, 1, -8),
		Size = UDim2.new(1, -16, 0, 36),
		Text = label,
		BackgroundColor3 = color,
	}, frame)
	action.Activated:Connect(function()
		if owned[def.Id] then
			spawnRemote:FireServer(def.Id)
			garage.Visible = false
		else
			buyRemote:FireServer(def.Id) -- 未解放・残高不足の判定はサーバー側
		end
	end)
end

function refreshGarage()
	refreshTabs()
	refreshPaint()
	clear(grid)
	local owned = ownedSet()
	local match = CATEGORIES[1].Match
	for _, cat in CATEGORIES do
		if cat.Id == category then
			match = cat.Match
		end
	end
	for i, def in Catalog.Vehicles do
		if match(def) then
			card(def, i, owned)
		end
	end
end

local function refreshEvents()
	clear(eventsList)
	for i, event in EventCatalog.Events do
		local lines = #event.Requirements
		local frame = new("Frame", { LayoutOrder = i, Size = UDim2.new(1, 0, 0, 60 + 22 * lines), BackgroundColor3 = CARD_BG }, eventsList)
		corner(frame, 10)
		local done = player:GetAttribute(`Done_{event.Id}`) == true
		local title = event.Name
		if event.Status == "planned" then
			title ..= "(準備中)"
		elseif done then
			title ..= " ✔ クリア"
		end
		text({
			Position = UDim2.fromOffset(10, 6),
			Size = UDim2.new(1, -20, 0, 22),
			Text = title,
			TextColor3 = done and Color3.fromRGB(120, 255, 120) or Color3.new(1, 1, 1),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, frame)
		text({
			Position = UDim2.fromOffset(10, 30),
			Size = UDim2.new(1, -20, 0, 18),
			Text = event.Description,
			TextColor3 = Color3.fromRGB(180, 180, 190),
			TextXAlignment = Enum.TextXAlignment.Left,
		}, frame)
		for j, req in event.Requirements do
			local value = math.min(player:GetAttribute(`Stat_{req.Stat}`) or 0, req.Target)
			text({
				Position = UDim2.fromOffset(18, 30 + 22 * j),
				Size = UDim2.new(1, -28, 0, 18),
				Text = `{req.Label or req.Stat}: {value}/{req.Target}`,
				TextColor3 = value >= req.Target and Color3.fromRGB(120, 255, 120) or Color3.new(1, 1, 1),
				TextXAlignment = Enum.TextXAlignment.Left,
			}, frame)
		end
	end
end

local function toggle(window: Frame)
	local show = not window.Visible
	garage.Visible = false
	eventsWindow.Visible = false
	window.Visible = show
end

garageButton.Activated:Connect(function()
	toggle(garage)
end)
eventsButton.Activated:Connect(function()
	toggle(eventsWindow)
end)
resetButton.Activated:Connect(function()
	resetRemote:FireServer()
end)
UserInputService.InputBegan:Connect(function(input, processed)
	if not processed and input.KeyCode == Enum.KeyCode.R then
		resetRemote:FireServer()
	end
end)

-- 属性(所持車/塗装/統計/クリア状況/リング進行)が変わったら描き直す。
-- 同じフレームに何度も変わることがあるので、次のフレームにまとめて1回だけ描く。
local pending = false
local function refreshAll()
	if pending then
		return
	end
	pending = true
	task.defer(function()
		pending = false
		cashLabel.Text = formatMoney(cash.Value)
		refreshGarage()
		refreshEvents()
		local total = player:GetAttribute("RingTotal")
		local nextRing = player:GetAttribute("RingNext")
		ringLabel.Visible = total ~= nil and nextRing ~= nil and nextRing > 1
		if ringLabel.Visible then
			ringLabel.Text = `RINGS {nextRing - 1}/{total}`
		end
	end)
end
player.AttributeChanged:Connect(refreshAll)
cash.Changed:Connect(refreshAll)
refreshAll()

-- ===== 通知 =====
notifyRemote.OnClientEvent:Connect(function(message: string)
	local toast = text({
		AnchorPoint = Vector2.new(0.5, 0),
		Position = UDim2.new(0.5, math.random(-40, 40), 0.3, 0),
		Size = UDim2.fromOffset(340, 36),
		Text = message,
		TextColor3 = Color3.fromRGB(255, 230, 80),
	}, gui)
	TweenService:Create(toast, TweenInfo.new(1.4), {
		Position = toast.Position - UDim2.fromOffset(0, 60),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	}):Play()
	Debris:AddItem(toast, 1.5)
end)

-- ===== 対決戦の表示 =====
local function clock(seconds: number): string
	seconds = math.max(0, math.floor(seconds))
	return string.format("%d:%02d", seconds // 60, seconds % 60)
end

local function updateShowdown()
	local state = ReplicatedStorage:FindFirstChild("Showdown")
	if not state then
		showdownLabel.Text = ""
		return
	end
	local now = workspace:GetServerTimeNow()
	if state:GetAttribute("Active") then
		showdownLabel.Text = `対決戦 {clock((state:GetAttribute("EndsAt") or now) - now)}   国産 {state:GetAttribute("ScoreJP") or 0} - {state:GetAttribute("ScoreOS") or 0} 海外`
	else
		local nextAt = state:GetAttribute("NextAt")
		showdownLabel.Text = nextAt and `次の対決戦まで {clock(nextAt - now)}` or ""
	end
end

-- ===== 速度 / 高度 / 体力 =====
RunService.RenderStepped:Connect(function()
	updateShowdown()

	local humanoid = player.Character and player.Character:FindFirstChildOfClass("Humanoid")
	local seat = humanoid and humanoid.SeatPart
	local car = seat and seat:IsA("VehicleSeat") and seat.Parent
	local chassis = car and car:FindFirstChild("Chassis")
	stats.Visible = chassis ~= nil
	if not chassis then
		return
	end

	-- 1 stud ~ 0.28 m
	local kmh = math.floor(chassis.AssemblyLinearVelocity.Magnitude * 0.28 * 3.6)
	local kind = car:GetAttribute("Kind")
	if kind == "plane" or kind == "heli" then
		speedLabel.Text = `{kmh} km/h   高度 {math.floor(chassis.Position.Y * 0.28)} m`
	else
		speedLabel.Text = `{kmh} km/h`
	end
	local ratio = math.clamp((car:GetAttribute("Health") or 0) / (car:GetAttribute("MaxHealth") or 1), 0, 1)
	healthFill.Size = UDim2.fromScale(ratio, 1)
	healthFill.BackgroundColor3 = Color3.fromRGB(220 * (1 - ratio) + 40, 220 * ratio + 20, 40)
end)

-- ===== コイン =====
local coins = player:WaitForChild("leaderstats"):WaitForChild("Coins")
local function updateCoins()
	coinsLabel.Text = `コイン {coins.Value}`
end
coins.Changed:Connect(updateCoins)
updateCoins()
