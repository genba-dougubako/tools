# CRUSH & FLY(クラッシュ＆フライ)— 車を潰して、空を飛べ！

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

VehicleFactory ──► CarBuilder / AircraftBuilder    Kind ごとの組み立てと塗装
VehicleControl (shared)  操縦の計算。運転している本人の端末で毎フレーム実行(ガタつき防止)
VehicleService     スポーン、購入(イベント未クリアは拒否)、物理担当の切り替え、塗装、速度の不正チェック
DamageService      衝突検知・体力・報酬(乗り物の種類を問わない)
PressService       プレス機 → EventService へ press_* を送る
RingService        リング通過判定 → コイン、EventService へ ring_pass / course_clear
EventService       統計の集計とイベントのクリア判定。クリアで「購入権」が解放される
LiftService        Sky Crane のウインチ(F で真下の車を吊る) → cars_lifted
ShowdownService    国産 vs 海外 対決戦(10 分ごとに 3 分間のラウンド) → showdown_win
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
| `src/shared/VehicleControl.luau` | 操縦ロジック(車・飛行機・ヘリ)。端末側で実行 |
| `src/shared/Paints.luau` | 塗装色の一覧 |
| `src/server/VehicleFactory.luau` | 種類ごとのビルダーへの窓口、塗装 |
| `src/server/CarBuilder.luau` | 車体・タイヤ・ステア・駆動 |
| `src/server/AircraftBuilder.luau` | 飛行機・ヘリ(アーケード式の飛行) |
| `src/server/VehicleService.luau` | スポーン/購入/リセット、毎フレームの操縦 |
| `src/server/DamageService.luau` | 衝突検知、パーツの変形/脱落、体力、報酬、爆発 |
| `src/server/PressService.luau` | プレス機の生成、作動の検証、潰れ演出、コイン付与、再出現 |
| `src/server/RingService.luau` | 空のリング(通過判定、コンボ、完走ボーナス) |
| `src/server/EventService.luau` | 統計とイベントのクリア判定 |
| `src/server/LiftService.luau` | Sky Crane のウインチ |
| `src/server/ShowdownService.luau` | 国産 vs 海外 対決戦のラウンド進行と勝敗 |
| `src/server/CoinService.luau` | コイン残高 |
| `src/server/DataService.luau` | DataStore によるお金・所持車のセーブ |
| `src/server/MapBuilder.luau` | テストマップ(道路、ジャンプ台、レンガ壁、巨大壁、ダミー車) |
| `src/client/HUD.client.luau` | 所持金/コイン、速度・高度・体力、ガレージ(国産車/海外車/飛行機・ヘリのタブ、色選び)、イベント、通知 |
| `src/client/VehicleController.client.luau` | 運転中の操縦(端末側)、携帯用の上昇/下降/吊るボタン |
| `src/client/Minimap.client.luau` | 右上の角の地図 |
| `src/client/Effects.client.luau` | プレス時のカメラ揺れ |

## 収録内容

- **車 44 台:** 国産系 21(新規 20 + Rusty Sedan)、海外系 23(新規 20 + 初期 3)。体格クラス(軽/ミニバン/SUV/ピックアップ/スポーツ/スーパーカーなど)ごとに形と性能が変わる。名前は全て自作、`Inspiration` に参考にした実在車をメモ。
- **飛行機 6:** Sky Trainer、Aero Stunt(複葉)、Bush Hopper(フロート)、Sky Jet、Air Liner(旅客機)、Strike Fighter
- **ヘリ 4:** Rescue Copter、Sky Crane(タンデムローター、車を吊れる)、Gunship、Tilt Rotor
- **イベント 4(クリアで購入権):**

| イベント | 条件 | 解放 |
| --- | --- | --- |
| Scrap Quota | プレス 5 台(国産系 2+、海外系 2+) | Heavy Truck、Sky Crane |
| Sky Ring Challenge | リング完走 1 回 | Sky Jet |
| Heavy Lift | Sky Crane で 3 台吊る | Gunship、Tilt Rotor |
| Domestic vs Import Showdown | 対決戦で勝った側に貢献 | Midship Blade、Wedge Supercar、Scarlet V8、Strike Fighter |

## 携帯でのガタつき対策(仕組み)

- **原因:** 以前は「操縦の計算 = サーバー」「物理の計算 = 運転者の端末」と分かれていた。サーバーの指示が通信の遅れで飛び飛びに届き、携帯ほど揺れが目立つ。
- **対策:** 操縦の計算を `VehicleControl`(共通モジュール)にまとめ、**運転している本人の端末**で毎フレーム実行する。物理と操縦が同じ端末で回るので、遅れがなくなる。
- 乗った瞬間に物理の担当をその人に渡し、降りたらサーバーに戻して動力を切る(`VehicleService` の Occupant 監視)。
- 端末側で操縦するぶん、サーバーは速度が車種の限界を大きく超えたら物理を取り上げる(簡易チート対策)。
- 携帯で飛行機・ヘリに乗ると、右下に「加速/上昇」「減速/下降」「吊る」ボタンが出る。

## ドリフト(ボタンなし)

急なハンドル操作をすると自動でドリフトに入る。速度が `DriftMinSpeed`(約 45 km/h)以上のときだけ。

| 入り方 | 条件 |
| --- | --- |
| 切り返し | 左右逆向きにハンドルを素早く振る(0.25 秒以内) |
| 急ハンドル | 一気にハンドルを切る(0.08 秒以内)。最高速度の 6 割以上のとき |
| ブレーキ + ハンドル | ブレーキ(S / スティック下)を踏みながら曲がる |

- ドリフト中は後輪のグリップが下がって車が横に滑り、車体の回転を補助する。速度でハンドルが弱まらないので、カウンターも当てられる。
- ハンドルを戻すか、速度が落ちると終わる。画面に「DRIFT 1.2s」、後輪からタイヤスモーク。
- 調整は `Config.luau` の `Drift...` の値(入りやすさ・滑り具合・回転の強さ)。
- タイヤスモークと「DRIFT」表示は運転している本人の画面だけに出る(他の人には車の滑る動きだけが見える)。

## 色と地図

- ガレージ上部の色見本で塗装を選べる(12 色 + 標準)。今乗っている乗り物もすぐ塗り直され、選んだ色はセーブされる。
- 右上の角に地図。道路・プレス機(P)・リング(次に通るものは緑で番号つき)・自分(矢印)・他の人(赤い点)。
- 標準のプレイヤー一覧は右上を占めるので隠している(`Config.HidePlayerList`)。地図の範囲は `MinimapCenter` / `MinimapRange`。

## 飛行機・ヘリの操作
- 飛行機: `W/S` 機首下げ/上げ、`A/D` 旋回、`E/Shift` 加速、`Q/Ctrl` 減速。離陸速度まで加速すると機首が上がる。
- ヘリ: `W/S` 前進/後退、`A/D` 旋回、`E/Shift` 上昇、`Q/Ctrl` 下降(押さなければホバリング)。
- Sky Crane: 車の真上で `F` を押すと吊る、もう一度 `F` で離す(誰も乗っていない車だけ)。
- 対決戦: 起動 1 分後から 10 分ごとに 3 分間。プレスで潰した車のデザイン(国産系/海外系)に点が入り、勝った側でプレスした人がクリア。
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
