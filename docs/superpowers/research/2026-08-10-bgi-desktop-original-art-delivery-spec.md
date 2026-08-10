# BGi Desktop：原創美術交付規格（高架線與霧金天際線）

> 日期：2026-08-10（Asia/Taipei）
> 狀態：可交付給原創美術製作的規格。本文不提供、下載或導入素材，亦不修改 Godot。
> 適用範圍：第一張完整背景「高架線與霧金天際線」、可自由拖放的前景掛件，以及桌面掛件介面 icon。

## 1. 交付原則

- 背景、前景掛件與 UI icon 必須獨立交付，檔案不可互相烘焙。
- 完整背景是可替換布景，不承載派遣、佔領、報酬或其他數值資訊。
- 掛件首次取得時可使用美術指定預設位置；玩家移動後，位置由遊戲資料保存，美術交付不得要求背景專屬掛點或格點限制。
- 動態效果是可選裝飾。所有資產必須先具有完整、可讀的靜態外觀。
- 交付檔與台帳只使用 ASCII 資產 ID 作程式鍵值；繁中顯示名稱另列。

## 2. 主題與構圖邊界

| 項目 | 規格 |
| --- | --- |
| 主題 ID | `skyline_goldline` |
| 顯示名稱 | 高架線與霧金天際線 |
| 視覺核心 | 深靛天空、低對比城市剪影、霧金高架線、少量可辨識窗燈與地面輪廓。 |
| 禁止承載 | 真實地名、真實組織、現實品牌、可交易貨幣標誌、任務數值或背景專屬掛件位置。 |
| 遠距辨識 | 在桌面掛件標準高度下，天空／高架線／城市輪廓三層仍須可辨識；亮部不可壓過任務與狀態文字。 |

## 3. 畫布、比例與安全範圍

Godot 桌面介面以 1280×260 為目前標準骨架。背景交付採相對畫布設計，程式可依實際可用工作區等比縮放或裁切。

| 資產類別 | 主畫布／比例 | 可視安全範圍 | 透明度要求 |
| --- | --- | --- | --- |
| 完整背景 `BG` | 1280×260，約 4.923:1 | 中央 70% 必須保有主題辨識；兩側 15% 不放唯一關鍵物件，以容納左右功能區。 | 可為不透明背景；若需要透明區，必須以 Alpha PNG 交付。 |
| 背景效果覆蓋 `BGFX` | 與對應背景完全相同的畫布與原點 | 不可依賴 UI 下方才可見的細節。 | Alpha PNG；透明區 alpha 為 0，半透明霧層可使用 0–255 alpha。 |
| 前景掛件 `FG` | 原始尺寸自訂；台帳須記錄像素尺寸與 `default_scale` | 構圖重要內容留在外框內至少 4px；不可含畫布背景色。 | Alpha PNG，未繪製區 alpha 為 0。 |
| 掛件效果覆蓋 `FGFX` | 與對應掛件主圖相同外框、原點與像素尺寸 | 不可超出主圖外框超過台帳載明的效果留白。 | Alpha PNG；效果可半透明。 |
| UI icon `UI` | 基準 24×24；可另交付 16×16、20×20、32×32 | 圖形四周至少保留 2px 視覺留白。 | Alpha PNG 或已核准的向量格式；不可含背景面板。 |

## 4. 分層與命名

| 顯示順序 | 層級 ID | 交付類別 | 檔名格式 | 範例 |
| ---: | --- | --- | --- | --- |
| 10 | `BG_SKYLINE_BASE` | 完整背景靜態主圖 | `bg_<theme>_<variant>_base.png` | `bg_skyline_goldline_default_base.png` |
| 20 | `BG_SKYLINE_FX` | 背景動態效果覆蓋與靜態備援 | `bgfx_<theme>_<variant>_<effect>.png` | `bgfx_skyline_goldline_rail_glow.png` |
| 30 | `FG_HANGER_WORLD` | 掛件靜態主圖 | `fg_<category>_<id>_base.png` | `fg_sign_001_base.png` |
| 40 | `FG_HANGER_FX` | 掛件動態效果覆蓋與靜態備援 | `fgfx_<category>_<id>_<effect>.png` | `fgfx_sign_001_neon_flicker.png` |
| 50 | `UI_SCENE_STATUS` | UI icon | `ui_<concept>_<style>_<size>.png` | `ui_mission_regular_24.png` |

資產 ID 與檔名對照如下：

| 類別 | 資產 ID 格式 | 範例 |
| --- | --- | --- |
| 背景 | `bg.<theme>.<variant>` | `bg.skyline_goldline.default` |
| 背景靜態備援 | `bg.<theme>.<variant>.fallback` | `bg.skyline_goldline.default.fallback` |
| 掛件 | `hanger.<category>.<id>` | `hanger.sign.001` |
| 掛件靜態備援 | `hanger.<category>.<id>.fallback` | `hanger.sign.001.fallback` |
| UI icon | `ui.<concept>.<style>` | `ui.mission.regular` |
| 效果插槽 | `fx.<owner-id>.<effect>` | `fx.bg.skyline_goldline.default.rail_glow` |

## 5. 每筆資產台帳欄位

美術交付須附一份機器可讀或表格化台帳；欄位名稱不得自行省略。

| 欄位 | 適用 | 說明 |
| --- | --- | --- |
| `asset_id` | 全部 | 穩定 ASCII 識別碼。 |
| `display_name_zh_hant` | 全部 | 繁中顯示名稱。 |
| `asset_version` | 全部 | 美術版本號。 |
| `file_name`、`file_hash` | 全部 | 交付檔案與雜湊。 |
| `canvas_width`、`canvas_height` | 圖像 | 實際像素尺寸。 |
| `layer_id` | 全部 | 對應第 4 節層級 ID。 |
| `author`、`rights_source` | 全部 | 原創作者與權利來源；未填者不得導入。 |
| `default_anchor` | 掛件 | 美術預設相對畫布座標，僅首次取得使用。 |
| `default_scale` | 掛件 | 預設顯示比例。 |
| `draggable` | 掛件 | 首版掛件必須為 `true`。 |
| `fallback_asset_id` | 背景／掛件／效果 | 對應正常靜態外觀。 |
| `effect_slots` | 背景／掛件 | 此 owner 擁有的效果插槽清單。 |

## 6. 動態效果插槽相容欄位

每個背景或掛件可宣告多個插槽。交付資產可支援以下效果類型：`pulse_light`、`flicker_light`、`float_offset`、`mist_drift`、`static`。

| 欄位 | 格式 | 美術交付要求 |
| --- | --- | --- |
| `slot_id` | 穩定字串 | 使用第 4 節效果插槽命名。 |
| `owner_id` | 背景或掛件 ID | 插槽只對應單一 owner。 |
| `effect_type` | 受控列舉 | 只能使用本節列出的類型。 |
| `enabled_default` | 布林值 | 預設是否建議啟用；程式可由玩家偏好覆寫。 |
| `intensity_default` | 0.0–1.0 | 僅描述視覺強度。 |
| `speed_default` | 0.0–1.0 | 僅描述正規化播放速度。 |
| `loop_mode` | `loop` 或 `once` | 常駐背景與掛件優先 `loop`。 |
| `fallback_asset_id` | 靜態資產 ID | 插槽關閉、缺檔或不支援時必須可正常顯示。 |
| `anchor_local` | 相對座標 | 僅可定義 owner 內部效果位置；不得覆寫玩家保存的掛件畫布座標。 |

效果檔無法播放、玩家選擇減少動態或效果欄位缺漏時，程式須呈現 `fallback_asset_id` 所指的靜態正常外觀。此行為不改變任務、地盤、收藏、報酬或掛件所有權。

## 7. 前景掛件自由拖放驗收

1. 新取得 `hanger.sign.001` 時，遊戲只讀取一次台帳中的 `default_anchor`。
2. 玩家將掛件拖到任意三個有效畫布位置後，保存相對畫布座標。
3. 切換背景、關閉動態、遺失效果檔、重啟遊戲後，該掛件的資產 ID、所有權、層級、顯示狀態、效果設定與玩家保存座標均不變。
4. 畫布尺寸或桌面配置變更後，如座標超出可見範圍，只可夾回最近可見邊界；不得回復 `default_anchor`、刪除或改變所有權。
5. 任何背景 PNG 與 BGFX PNG 均不可含入已取得掛件的圖像，避免背景替換製造重複或遺失的視覺結果。

## 8. 可替換背景驗收

1. 只載入 `BG_SKYLINE_BASE` 時，背景已完整呈現高架線與霧金天際線的靜態主題。
2. 所有 `BG_SKYLINE_FX` 關閉或缺漏時，背景仍可讀，沒有透明破洞、黑色遮罩或依賴動畫才成立的資訊。
3. 載入另一張完整背景後，只允許背景及其 `BGFX` 替換；`FG_HANGER_WORLD`、`FG_HANGER_FX` 與 UI icon 不被替換、重置或移動。
4. 背景構圖不得占用左右功能區的必要文字與按鈕可讀範圍；若實作提供緊湊版，背景主題仍須可辨識。

## 9. UI icon 最小交付集合

| 概念 | 資產 ID | 圖形語意 | 狀態需求 |
| --- | --- | --- | --- |
| 地盤 | `ui.territory.regular` | 地圖與旗標 | 一般／鎖定／可推進 |
| 布置 | `ui.decorate.regular` | 展示座或方塊 | 一般／可放置 |
| 任務 | `ui.mission.regular` | 密封文件或印章 | 一般／派遣中／完成 |
| 收取 | `ui.claim.regular` | 收納盤或向下箭頭 | 不可用／可收取 |
| 刷新 | `ui.refresh.regular` | 循環箭頭 | 無額度／可刷新 |
| 隊伍 | `ui.crew.regular` | 多人輪廓 | 可用／忙碌 |
| 倒數 | `ui.timer.regular` | 計時器 | 一般／即將完成 |
| 收藏 | `ui.collection.regular` | 展示盒或獎章 | 空／新增 |
| 設定 | `ui.settings.regular` | 齒輪 | 一般 |
| 收合 | `ui.collapse.regular` | 方向箭頭 | 展開／收合 |

icon 在深色底上需要以輪廓、填色或角標共同表現狀態；不得只依賴顏色傳遞可用、派遣中或待收取的差異。

## 10. 交付前檢核

- [ ] 背景、掛件、效果與 UI icon 各自獨立檔案，檔名與台帳 `asset_id` 對應。
- [ ] 每個背景與掛件皆有可讀的靜態主圖或靜態備援。
- [ ] 每個效果插槽都填有第 6 節完整欄位。
- [ ] 每個掛件都提供首次取得用的 `default_anchor`，且 `draggable=true`。
- [ ] 背景圖不包含前景掛件；效果覆蓋不改變掛件畫布座標。
- [ ] 權利來源、作者、版本、雜湊與授權條件皆已記錄。
- [ ] 在標準與緊湊桌面配置下，完成第 7 與第 8 節驗收。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 日期時間 | 2026-08-10 Asia/Taipei |
| 類型 | 美術規格 |
| 目標 | 將已確認的「高架線與霧金天際線」方向轉成可供原創美術製作與程式驗收的交付規格。 |
| 檔案 | `docs/superpowers/research/2026-08-10-bgi-desktop-original-art-delivery-spec.md` |
| 變更範圍 | 全檔新增；涵蓋資產命名、1280×260 相對畫布、透明與分層、台帳欄位、動態插槽、靜態備援、背景替換與自由拖放驗收。 |
| 驗證 | 僅新增 Markdown 規格；未下載或導入素材、未修改 Godot、未執行 Git 操作。 |
| 後續 | 原創美術開始製作前，確認作者、權利移轉與最終交付格式；導入前再建立素材台帳與驗收流程。 |
