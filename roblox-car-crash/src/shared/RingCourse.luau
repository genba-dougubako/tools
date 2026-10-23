-- 空のリングコース。順番に通ると進行し、全部通るとクリア。
-- 座標はワールド座標(テストマップの道路の上空)。別マップに入れるときはここだけ調整する。
return {
	Radius = 22,
	Points = {
		Vector3.new(0, 55, -90),
		Vector3.new(0, 75, -190),
		Vector3.new(40, 95, -290),
		Vector3.new(100, 115, -370),
		Vector3.new(170, 120, -310),
		Vector3.new(200, 100, -210),
		Vector3.new(170, 80, -110),
		Vector3.new(100, 70, -30),
		Vector3.new(30, 85, 40),
		Vector3.new(-40, 100, -40),
	},
}
