# BGi Desktop：UI icon 語意盤點與來源候選表

> 日期：2026-08-10（Asia/Taipei）
> 狀態：研究規格。未下載、導入或修改任何素材、Godot 或 Git。
> 前提：功能 icon 與主視覺插圖分離；首版可使用合規 placeholder 驗證操作，成品風格資產另由原創美術交付。

## 1. 尺寸級別與來源判定

| 級別 | 基準尺寸 | 用途 | Phosphor MIT placeholder | 原創需求 |
| --- | ---: | --- | --- | --- |
| `S` | 16px | 狀態角標、資源列、小型提示 | 可用 | 不需要，除非成為產品識別。 |
| `M` | 24px | 主要功能按鈕、任務卡、側欄入口 | 可用 | 可於正式 UI 階段替換。 |
| `L` | 32px | 主分頁、可收取提示、重要確認視窗 | 可用於 MVP | 建議於正式 UI 階段設計統一容器與狀態造型。 |
| `XL` | 48px 以上 | 地盤徽章、角色頭圖預留、收藏縮圖、黑市物件 | 不適合只用通用 icon | 必須原創或具明確商用權利的插圖。 |

Phosphor Icons 官方明示採 MIT 授權；MIT 要求散布時保留 copyright 與 permission notice。可作功能性 placeholder，不能取代 BGi 的背景、掛件、角色、收藏物、黑市交易物件或產品識別圖形。來源：[官方網站](https://phosphoricons.com/)／[官方 LICENSE](https://github.com/phosphor-icons/core/blob/main/LICENSE)。

## 2. 功能 icon 對照

| 功能區 | 資產 ID | 圖形語意 | 狀態 | 級別 | Phosphor placeholder | 原創需求 |
| --- | --- | --- | --- | --- | --- | --- |
| 地盤 | `ui.territory.regular` | 地圖加旗標 | 鎖定／可推進／已觸及／已占據 | L | `map-trifold`、`flag` | 地盤徽章與四階段成長圖像需原創。 |
| 布置 | `ui.decorate.regular` | 展示座或方塊 | 無物件／可放置／已布置 | L | `cube`、`armchair` | 環境物件縮圖與展示座需原創。 |
| 任務 | `ui.mission.regular` | 密封文件或印章 | 可接取／派遣中／完成待收取 | L | `seal`、`clipboard-text` | 任務類型章紋可於正式 UI 原創化。 |
| 收取 | `ui.claim.regular` | 收納盤與向下箭頭 | 不可收取／可收取／已收取 | L | `tray-arrow-down` | 不需要；可沿用 placeholder。 |
| 刷新 | `ui.refresh.regular` | 循環箭頭 | 無額度／可刷新／刷新後 | M | `arrows-clockwise` | 不需要。 |
| 隊伍 | `ui.crew.regular` | 多人輪廓 | 可用／忙碌／人數不足／達上限 | M | `users-three`、`user-minus` | 角色 token 與頭圖需原創。 |
| 倒數 | `ui.timer.regular` | 計時器 | 未開始／進行中／即將完成／完成 | M | `timer`、`clock-countdown` | 不需要。 |
| 黑市 | `ui.black_market.regular` | 密封信封與交換箭頭 | 鎖定／可進入／可刷新／新品 | L | `envelope-seal`、`arrows-left-right` | 商品框、稀有度章與交易演出需原創。 |
| 裝備 | `ui.equipment.regular` | 背包與格槽 | 空槽／已裝備／可鑲嵌／詞條固定 | M | `backpack`、`squares-four` | 裝備插圖與詞條符號需原創。 |
| 收藏 | `ui.collection.regular` | 展示盒或獎章 | 空／新增／可查看／已完成套組 | L | `archive-box`、`medal` | 收藏圖鑑、縮圖與套組插圖需原創。 |
| 角色 | `ui.character.regular` | 人物輪廓與資訊卡 | 可用／派遣中／解鎖／未解鎖 | L | `user-circle`、`identification-card` | 角色頭圖與個性徽章需原創。 |
| 設定 | `ui.settings.regular` | 齒輪 | 一般／已開啟 | M | `gear-six` | 不需要。 |
| 背景收藏 | `ui.backgrounds.regular` | 疊放風景卡 | 新增／目前套用／未套用 | M | `images-square` | 背景縮圖與主題徽章需原創。 |
| 掛件 | `ui.hangers.regular` | 吊牌或展示框 | 未取得／可放置／已放置／可拖放 | M | `tag`、`frame-corners` | 各掛件主圖與特效需原創。 |
| 動態偏好 | `ui.motion.regular` | 光芒與切換 | 啟用／停用／靜態備援 | S | `sparkle`、`toggle-left`、`toggle-right` | 不需要。 |
| 資訊 | `ui.info.regular` | 圓形 i | 一般／提示 | S | `info` | 不需要。 |
| 鎖定 | `ui.locked.regular` | 鎖頭 | 鎖定／解鎖 | S | `lock`、`lock-key-open` | 不需要。 |
| 收合 | `ui.collapse.regular` | 方向箭頭 | 展開／收合 | M | `caret-down`、`caret-up` | 不需要。 |

## 3. 不可用 placeholder 取代的視覺資產

| 類別 | 原因 | 所需權利 |
| --- | --- | --- |
| 高架線與霧金天際線完整背景 | 是產品主視覺與長期場景成長載體。 | 原創內製或委託權利移轉／全球商用授權。 |
| 前景掛件：旗幟、霓虹招牌、吊牌、展示框、收藏陳列物 | 需維持 BGi 主題一致性，且要支援自由拖放與獨立效果。 | 原創內製或委託權利移轉／全球商用授權。 |
| 小弟與解鎖角色頭圖 | 角色可辨識性與後續敘事用途。 | 原創內製或委託權利移轉／全球商用授權。 |
| 黑市商品、武器、飾品、防具與稀有度圖示 | 需要避免真實品牌、武器教學與第三方作品混入。 | 原創內製或逐項明確商用授權。 |
| 地盤階段、收藏套組、主題背景縮圖 | 直接傳達長期成長。 | 原創內製或逐項明確商用授權。 |

## 4. 高架線與霧金天際線前景掛件清單

| 掛件 ID | 顯示名稱 | 類別 | 初始可用狀態 | 動態插槽候選 | 權利需求 |
| --- | --- | --- | --- | --- | --- |
| `hanger.sign.001` | 霧金霓虹招牌 | 招牌 | 鎖定，取得後可放置 | `flicker_light` | 原創商用權利；獨立 Alpha 主圖與靜態備援。 |
| `hanger.flag.001` | 勢力旗幟 | 旗幟 | 鎖定，取得後可放置 | `float_offset` | 原創商用權利；不得使用真實組織符號。 |
| `hanger.frame.001` | 收藏展示框 | 展示 | 鎖定，取得後可放置 | `pulse_light` | 原創商用權利；內容與外框分離。 |
| `hanger.lantern.001` | 低照度路燈 | 光源 | 鎖定，取得後可放置 | `pulse_light` | 原創商用權利；停用動態仍有正常外觀。 |
| `hanger.crate.001` | 封條運輸箱 | 陳列物 | 鎖定，取得後可放置 | `static` | 原創商用權利；不可採真實品牌或現金標誌。 |
| `hanger.banner.001` | 高架線宣傳吊幅 | 場景裝飾 | 鎖定，取得後可放置 | `float_offset` | 原創商用權利；不含真實地名或品牌。 |
| `hanger.case.001` | 黑市展示箱 | 收藏陳列 | 鎖定，取得後可放置 | `pulse_light` | 原創商用權利；商品內容另作獨立資產。 |
| `hanger.mistlamp.001` | 霧燈組 | 環境光 | 鎖定，取得後可放置 | `mist_drift` | 原創商用權利；可與背景霧層分開載入。 |

所有前景掛件均須符合既有自由拖放規格：美術只提供首次 `default_anchor`，玩家移動後的相對畫布座標不由素材或背景覆寫。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 日期時間 | 2026-08-10 Asia/Taipei |
| 類型 | UI／美術研究 |
| 目標 | 建立桌面地盤、任務、黑市、角色、收藏與設定的 icon 語意、狀態、尺寸、placeholder 與原創邊界。 |
| 檔案 | `docs/superpowers/research/2026-08-10-bgi-desktop-ui-icon-semantics-and-source-candidates.md` |
| 證據 | Phosphor 官方網站與官方 MIT LICENSE。 |
| 驗證 | 僅新增 Markdown；未下載、導入素材，未修改 Godot 或 Git。 |
| 下一步 | 依同輪工作建立 UI 視覺階層與狀態色規範。 |
