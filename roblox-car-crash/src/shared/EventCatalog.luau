-- イベント定義。Requirements は「統計(Stat)がTarget以上」の組み合わせ。
-- 統計はサーバー側の各機能が EventService.add(player, stat, n) で加算する。
-- クリアすると Unlocks の乗り物/施設が「購入可能」になる(自動で貰えるわけではない)。
-- Status = "planned" は予告表示のみ(未実装)。
local Events = {
	{
		Id = "scrap_quota",
		Name = "Scrap Quota",
		Description = "Crush 5 cars in the press (2+ domestic-style, 2+ import-style).",
		Requirements = {
			{ Stat = "press_total", Target = 5, Label = "Cars crushed" },
			{ Stat = "press_jp", Target = 2, Label = "Domestic-style" },
			{ Stat = "press_os", Target = 2, Label = "Import-style" },
		},
		Unlocks = { Vehicles = { "truck" }, Facilities = { "press_lv2" } },
		Status = "active",
	},
	{
		Id = "sky_rings",
		Name = "Sky Ring Challenge",
		Description = "Fly through every ring of the sky course.",
		Requirements = {
			{ Stat = "course_clear", Target = 1, Label = "Course clears" },
		},
		Unlocks = { Vehicles = { "jet" } },
		Status = "active",
	},
	{
		Id = "jp_vs_os",
		Name = "Domestic vs Import Showdown",
		Description = "Server-wide team battle. Coming soon.",
		Requirements = {},
		Unlocks = {},
		Status = "planned",
	},
}

local ById = {}
for _, event in Events do
	ById[event.Id] = event
end

return { Events = Events, ById = ById }
