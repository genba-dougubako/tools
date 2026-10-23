# Car Crash (Roblox) — Car Crushers 2 系プロトタイプ + 空のリング

車を運転して、壁・ジャンプ台・ダミー車に突っ込んで壊し、その分だけお金がもらえる → 新しい車を買う、というゲームの土台です。
車は全部コード(Part + 拘束)で組み立てているので、外部アセットは不要です。

## セットアップ

1. [Rojo](https://rojo.space/) をインストール(Studio プラグイン + CLI)
2. このフォルダで `rojo serve` → Studio の Rojo プラグインから Connect
   (または `rojo build -o CarCrash.rbxl` で place ファイルを作る)
3. Studio の Game Settings → Security で **Enable Studio Access to API Services** をオンにするとセーブも試せます(オフでも動作はします)

## 遊び方

- スポーン後、画面左の **GARAGE → SPAWN** で車を出す(最初は Rusty Sedan のみ)
- `W/S` or 矢印: アクセル/ブレーキ、`A/D`: ハンドル、`R`: 車をリセット(修理)
- 壁・バリア・ダミー車・ジャンプ台で衝突 → ダメージに応じて `$` が貯まる
- 他プレイヤーやダミー車を壊すと `SMASH` ボーナス、撃破で `WRECKED!` ボーナス
- 貯めたお金で GARAGE から新しい車を購入

## プレス機(車を潰して +100 コイン)

- スポーン地点の東に大型プレス機があり、操作盤の赤ボタン(`Start Press`)で作動
- 自分の車をプレス内に停めて押す → 警告灯 → 打ち下ろし → 火花/煙/カメラ揺れ → `+100 COINS` → 車を入口の外に再出現
- 判定はすべてサーバー側(車の所有者、プレス内に収まっているか、距離、占有中か、二重報酬防止)
- 検証手順は `STUDIO_TEST_CHECKLIST.md` を参照

## 全体の設計(「データを足せば増える」)

```
VehicleCatalog (shared)  乗り物のデータ。Kind = car / plane / heli
EventCatalog   (shared)  イベントのデータ。クリア条件 = 統計(Stat)の目標値
RingCourse     (shared)  空のリングコースの座標

VehicleFactory ──► CarBuilder / AircraftBuilder    Kind ごとの生成と操縦(rig.Update / rig.Idle)
VehicleService     スポーン、購入(イベント未クリアは拒否)、毎フレームの操縦
DamageService      衝突検知・体力・報酬(乗り物の種類を問わない)
PressService       プレス機 → EventService へ press_* を送る
RingService        リング通過判定 → コイン、EventService へ ring_pass / course_clear
EventService       統計の集計とイベントのクリア判定。クリアで「購入権」が解放される
CoinService        コイン残高
```

### 増やし方
- **乗り物を足す:** `VehicleCatalog.luau` に1項目足すだけ(`RequiresEvent` を付けるとイベント報酬になる)。新しい種類(船など)は Builder を作って `VehicleFactory` に登録。
- **イベントを足す:** `EventCatalog.luau` に1項目足す。条件は `Stat` と `Target`。
- **新しい遊びを足す:** 機能側で `EventService.add(player, "好きな統計名", 1)` を呼べば、その統計をイベントの条件に使える。`Main.server.luau` に `init` を1行足す。
- **「購入権」の設計:** イベントクリアは「買えるようになる」だけで、車は貰えない。お金(現金 `$`)で買う。Robux 課金は未実装(承認が必要なため)。
- 予告用の `Status = "planned"` イベントは UI に「COMING SOON」と出る(国産 vs 海外の対決戦が入っている)。

## 構成

| ファイル | 役割 |
| --- | --- |
| `src/shared/Config.luau` | 報酬・衝撃しきい値・リング・プレスの調整値 |
| `src/shared/VehicleCatalog.luau` | 車・飛行機・ヘリの定義 |
| `src/shared/EventCatalog.luau` | イベントの定義 |
| `src/shared/RingCourse.luau` | リングの座標 |
| `src/server/VehicleFactory.luau` | 種類ごとのビルダーへの窓口 |
| `src/server/CarBuilder.luau` | 車体・タイヤ・ステア・駆動 |
| `src/server/AircraftBuilder.luau` | 飛行機・ヘリ(アーケード式の飛行) |
| `src/server/VehicleService.luau` | スポーン/購入/リセット、毎フレームの操縦 |
| `src/server/DamageService.luau` | 衝突検知、パーツの変形/脱落、体力、報酬、爆発 |
| `src/server/PressService.luau` | プレス機の生成、作動の検証、潰れ演出、コイン付与、再出現 |
| `src/server/RingService.luau` | 空のリング(通過判定、コンボ、完走ボーナス) |
| `src/server/EventService.luau` | 統計とイベントのクリア判定 |
| `src/server/CoinService.luau` | コイン残高 |
| `src/server/DataService.luau` | DataStore によるお金・所持車のセーブ |
| `src/server/MapBuilder.luau` | テストマップ(道路、ジャンプ台、レンガ壁、巨大壁、ダミー車) |
| `src/client/HUD.client.luau` | 所持金/コイン、速度・高度・体力、ガレージ、イベント一覧、通知 |
| `src/client/Flight.client.luau` | 飛行機・ヘリの上下入力(E/Shift 上、Q/Ctrl 下) |
| `src/client/Effects.client.luau` | プレス時のカメラ揺れ |

## 飛行機・ヘリの操作
- 飛行機: `W/S` 機首下げ/上げ、`A/D` 旋回、`E/Shift` 加速、`Q/Ctrl` 減速。離陸速度まで加速すると機首が上がる。
- ヘリ: `W/S` 前進/後退、`A/D` 旋回、`E/Shift` 上昇、`Q/Ctrl` 下降(押さなければホバリング)。
- リング: 番号順に通る。連続で通るとコンボ加算、15 秒以内に次を通れないとやり直し、全部通ると完走ボーナス +100。

## 衝突ダメージの仕組み

毎フレームの車体速度を `ImpactWindow` 秒ぶん記憶し、その間の速度変化が `ImpactThreshold` を超えたらクラッシュ扱い。
速度変化の向き = ぶつかった方向なので、その付近の車体パーツ(`Weld.C0`)を凹ませ、大きい衝撃ではパーツを外します。

## 調整ポイント(未テストの部分)

Studio 外で書いたため実機未検証です。最初に確認してほしい点:

- **前進/ハンドルが逆**: `Config.DriveSign` / `Config.SteerSign` を `-1` に
- **すぐ壊れる/壊れない**: `ImpactThreshold`、車ごとの `DamageScale`
- **稼ぎすぎ/少なすぎ**: `CashPerDamage`、`HitCashPerDamage`

## 次にやると良いこと

- サスペンション(SpringConstraint)と見た目のタイヤ回転
- 本格的な車モデルへの差し替え(`CarBuilder.build` の Rig 構造を保てばOK)
- 爆発/ロケット/落下エリアなどの「壊す」ギミック、ワールド拡張、ミッション、ランキング
