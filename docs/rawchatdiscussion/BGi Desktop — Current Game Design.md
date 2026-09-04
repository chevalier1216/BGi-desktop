# BGi Desktop — Current Game Design

> Human-readable design view，不是 authoritative source。
> Authoritative sources 為 Git repository 中的正式 specs / decisions；若本文件與其衝突，以正式來源為準。
> Source revision：以 Git repository 中目前正式 specs / decisions 為準；實際發布 revision 以 Git commit 記錄為準。

## 1. 遊戲概念與玩家身份

玩家在 Windows 桌面上經營虛構街區勢力。這是一款低壓、桌面常駐、放置型的地盤擴張遊戲：派遣人物、等待任務、收取成果、推進地盤，逐漸讓街區呈現「我已占據這裡」的樣貌。

遊戲不使用 GPS、真實位置、真實貨幣、玩家交易、PvP 或地盤被奪回機制。

## 2. 玩家目標

- 短期：完成派遣、等待與收取的任務循環。
- 中期：觸及新地盤、解鎖人物、開放更多任務與場景內容。
- 長期：占據街區、累積背景、收藏、環境物件與可見勢力成長。

## 3. 核心循環

### 即時循環

選取可用任務 → 選擇可用人物 → 確認派遣 → 觀看倒數 → 任務完成 → 收取成果。

### 單次開啟循環

開啟遊戲後，系統依本機時間結算任務；玩家查看待收取結果、處理地盤與收藏提示，再派出下一輪任務。

### 長期循環

任務成果推進地盤與內容；玩家取得更多人物、地盤、收藏與街區外觀，並持續維持桌面上的勢力景觀。

## 4. 小弟／人物系統

玩家以 5 名外觀相同、但彼此獨立且可持久化的 roster Unit 開始。每名 Unit 同時只能參與一個任務；一個任務可派遣多名 Unit。這 5 名 Unit 都參照同一 Character Type `character.worker01`；Character Type 不等於 roster Unit identity。

`starter_18 → territory_02` 的 source 維持不變。首次成功收取時，玩家新增 1 名獨立、可持久化且可派遣的 roster Unit，同樣參照 `character.worker01`；因此 roster 由 5 名變為 6 名，不會解鎖新的 Character Type。該地盤與新增 Unit 的產品結果在任務完成、進入待收取前即已固定；實際成功收取才讓玩家取得這項進度。Unit ID 格式、生成方式、技術欄位與 descriptor schema 尚未由產品設計決定。任務最低／最高人數、團隊倍率公式與非新手人物內容均維持 `[PLACEHOLDER]`。

Unit 狀態以可用與派遣中為核心。任務完成待收取是任務狀態，不會把原派遣 Unit 持續鎖為忙碌。

## 5. 任務系統

任務包含基礎地盤任務、影響力推進任務與探索採集任務；已占據地盤可開放高階探索採集任務。

新手任務固定為 T01–T23，依序進行。新手任務不會被刷新替換；對新手任務執行刷新不改變任務，也不消耗刷新額度。

正式任務刷新每 6 小時補充 1 次額度，上限為 1，只能替換尚未接受的任務。已派遣、待收取與已收取任務都不可被刷新。

第一版不提供玩家取消任務。

首批固定的教學任務成果以 canonical `mission_template_id` 記錄：`starter_18` 觸及 `territory_02` 並新增 1 名參照 `character.worker01` 的獨立 roster Unit；`starter_19`–`starter_23` 分別取得特級金磚、水果禮盒、LED 霓虹招牌、BEMZ 豪華保母車與城市建築套組，各為固定 1 份。這些成果在任務完成時固定，成功收取才入帳。

另有一項已核准的正式探索任務 mapping：`mission.r01.explore_001` 在任務完成時固定 `collectible_grant`，成功收取後取得 `collectible.r01.poster_001` ×1。這只界定此任務的一次固定成果；不決定其他任務、掉落／機率、收藏用途、系列獎勵或展示／placement。

另一項已核准的正式探索任務 mapping：`mission.r01.explore_002` 在任務完成時固定 `collectible_grant`，成功收取後取得 `collectible.r01.poster_002` ×1。這同樣只界定此任務的一次固定成果；不決定其他任務、掉落／機率、收藏用途、系列獎勵或展示／placement。後續 territory-first-touch direction 尚待新的設計決策，未有任務、地盤、人物或效果 identity。

另一項已核准的正式探索任務 mapping：`mission.r01.explore_003` 在任務完成時固定 `collectible_grant`，成功收取後取得 `collectible.r01.poster_003` ×1。這同樣只界定此任務的一次固定成果；不決定其他任務、poster 來源、掉落／機率、收藏用途、系列獎勵或展示／placement。

已核准的 Territory 03 mapping 為：`mission.r01.territory_001` 在完成時固定 `territory_first_touch`；成功收取後首次觸及 `territory_03`，並新增 1 名參照 `character.worker02` 的獨立 roster Unit。它不決定其他地盤或人物的 mapping。

## 6. 報酬與收取

每張任務需明示：

- 保底報酬；
- 額外報酬範圍；
- 額外報酬機率；
- 團隊倍率說明。

任務一定有保底。額外報酬可為 0；此時顯示「未取得額外獎勵」，不能呈現為任務失敗或空手而回。

任務到期後，結果和本次會套用的成果內容會先一併固定並保存為 `completed_pending_claim`；之後不會因設定、掉落表或重啟而重新抽取。原派遣人物立即恢復可用，可參與其他任務；但報酬、地盤推進、收藏、人物解鎖與教學進度，僅在成功收取後套用。

收取失敗時，任務保持待收取、結果不重抽、長期效果不重複套用，人物也不得回退為派遣中。

## 7. 地盤系統

每個街區有四段進度：

1. 未涉足：顯示輪廓與解鎖條件。
2. 已觸及：成功收取帶有首次觸及成果的任務，解鎖該次已固定的 1 名人物與基礎任務。
3. 施加影響：累積部分影響力，開放更多任務。
4. 已占據：出現可見場景變化、開放高階探索採集任務與環境物件放置。

地盤不會被其他勢力奪回，也不會倒退。地盤數量、解鎖順序、影響力門檻均為 `[PLACEHOLDER]`。

第一版不建立 Region 或 `region_id`。`territory_01`、`territory_02`、`territory_03` 分別是第一、第二、第三張地圖；舊 `region.r01` 世界／地圖命名規則已被 supersede。`rXX` 只代表 playthrough／content-cycle namespace，不代表 Region、Map 或 Territory，因此既有 `mission.r01.*`、`collectible.r01.*`、`background.r01.*` ID 維持不變。

Territory 03 的已核准內容範圍為 `character.worker02`、`character.handyman01`、`character.assassin01`、`character.gangster01`。只有 `character.worker02` 已指定為首次觸及新增 Unit 的 Type；其餘三者的解鎖、出現與派遣順序均尚待決策。

## 8. 收藏系統

探索採集任務是收藏主要來源；收藏也可作為任務額外獎勵。這不代表所有任務都會直接產出收藏。

收藏展示分為：

- 完整背景：替換整個場景背景。
- 前景掛件：場景覆蓋層，可自由拖放並保存位置。
- 場景物件：顯示於場景，但不是自由拖放掛件。
- 場景套件：整組場景 Layer；同類別同一背景一次只展示一套。
- 純收藏：只存在收藏介面／Icon 層。

第一批方向：

| 類型 | 已確認內容 |
| --- | --- |
| 前景掛件 | LED 霓虹招牌、懸賞令 |
| 場景物件 | BEMZ 豪華保母車、總部大樓 |
| 場景套件 | 城市建築套組 |
| 純收藏 | 999K 特級金磚、市長的水果禮盒、檳榔西施的寫真 |

收藏可為 Unique、Stackable 或 Series。水果禮盒確認可堆疊；LED、懸賞令與後續多款 BEMZ 原則上屬不同具名收藏的 Series 成員。

任務在完成時可固定一筆收藏取得成果，成功收取才寫入收藏庫。Unique 未擁有時取得；重複取得不會改抽或替換。Stackable 依完成時已固定的數量只增加一次；Series 採相同收取方式，系列關係只作內容分類。

上述新手固定成果只定義這六個任務；其餘新手任務、完整收藏對照、掉落／機率、未來水果禮盒數量、Stackable 用途與 Series 完成獎勵均尚待決策。

收藏與資源採 identity-first ID；內容身份、展示方式、所有權規則與 Series 關係分開表示。

## 9. 布置／環境物件

環境布置的首要目的，是增加「我已占據這裡」的可見感受。物件可提供小幅、可讀且有上限的效果，但具體效果、數值與上限仍為 `[PLACEHOLDER]`。

場景物件與環境布置不是同義概念。場景物件與場景套件取得時只建立所有權，不會自動顯示、套用或放置。其 placement UX 尚待決策，不能自行套用前景掛件的自由拖放規則。

## 10. 背景系統

每個地區可在指定地盤進度節點解鎖 1 張完整背景。第一張背景主題為「高架線與霧金天際線」。

背景解鎖後先收入背景收藏庫，不會自動套用。玩家每次切換背景前都需要確認；若選擇暫不更換，背景仍留在收藏庫。

前景掛件獨立於背景：可自由拖放、保存相對畫布位置與層級。背景切換、動態效果切換、重啟與故障復原都不得重置掛件的所有權、位置、層級或顯示狀態。

背景與前景掛件可各自使用動態效果插槽；無法使用時需以靜態外觀正常呈現，且動態效果不得改變遊戲數值。

## 11. 黑市

黑市維持最低優先度。可保留鎖定入口，但交易、內容、價格、貨幣與解鎖條件皆尚待決策；目前沒有已核准的黑市玩法。

## 12. UI 與桌面互動

BGi Desktop 只使用一個覆蓋 Windows 桌面可用區的 OS-level 主視窗。未繪製 BGi UI 的透明區域可 click-through，讓玩家操作後方 Windows 桌面或其他應用程式。

任務、任務詳情、地盤、黑市、角色、收藏與設定都使用同一主視窗內的 in-app panel／widget，不會開啟額外 Windows native child window。panel 可拖曳至整個桌面可用區，不受底部場景區域裁切；每個 panel 都有可見關閉操作。`ESC` 關閉目前 z-order 最上層 panel；重複按下會依 z-order 向下關閉。任務清單與任務詳情必須呈現實際內容，不得只開啟空白 panel。

主要入口為地盤、黑市、角色、收藏與設定。場景區顯示完整背景、前景掛件、場景物件／套件與人物狀態；任務 panel 是唯一可派遣、收取與刷新的位置。

UI 行動優先序：

1. 存檔錯誤／`recovery_hold`
2. 可收取成果
3. 派遣確認
4. 派遣中任務與刷新
5. 首次觸及、人物解鎖、新背景與新收藏提示
6. 報酬機率、黑市詳情與歷史紀錄

行動優先序決定提示與 panel z-order，不限制玩家把 panel 拖曳到桌面可用區的任何位置。

日常 player-visible UI 驗收優先在 Godot editor 的 embedded game／in-editor execution 完成；headless 測試只能驗證狀態與資料契約，不能單獨證明可見 UI 已完成。桌面透明、click-through 與和 Windows／其他應用程式互動，則在 native desktop／exported executable 的 milestone 或 integration acceptance 驗證，不是每個一般 Coding mission 的例行方式。

首次觸及成功套用後，玩家只會看到兩項新成果：地盤由「未涉足」變為「已觸及」，以及解鎖人物 ×1。重複收取、重新載入、重看結果與背景切換不會再產生人物、地盤變更或新的解鎖通知。

## 13. 新手流程

新手以固定 T01–T23 順序介紹任務卡、選人、多人派遣、等待、收取與成果推進。

中斷後，系統依已保存的任務／教學狀態復原。若存在待收取任務，玩家先回到收取成果；成功收取後才推進下一個新手步驟。新手固定任務不會被刷新跳過。

在沒有正式美術時，文字暫代 UI 仍須能操作人物狀態、任務卡、派遣、倒數、收取、報酬、地盤進度、收藏與人物解鎖。

## 14. 長期成長與資料安全

長期成長以地盤進度、探索收藏與環境布置為可見證據。背景、掛件、場景物件、場景套件與純收藏的所有權均需獨立保存。

第一版以本機存檔為權威；Steam Cloud 是後續整合。任務結果與其已固定成果在待收取前一併保存；重啟不得重骰、重算或用目前內容設定替換原成果。資料不足或不一致時，系統進入安全復原狀態，不得自動補發成果或猜測人物狀態。

## 15. 地盤受損

已占據地盤未來可出現受損 condition。它不是第五個地盤階段，也不會影響地盤所有權、進度或已取得收藏。

已核准內容：

- 場景有可見受損效果。
- 玩家點擊受損位置，開啟修復選單。
- 可立即支付貨幣修復，或派遣人物等待修復完成。
- 受損物件若有已核准效果，該效果僅暫時失效至修復完成。

受損啟用條件、離線資格、檢查週期、機率、成本、人數、時長、同時受損數量與程度分級均為 `[PLACEHOLDER]`。

## 16. 目前仍待決策

詳見 Design Discussion Backlog。未決項目不改變目前 P0 任務生命週期與核心桌面循環的已核准規則。

## 17. Source Map

- 地盤、收藏、背景、布置、受損：[territory-exploration-design.md](G:\Projects\BGi-Desktop\docs\superpowers\specs\2026-08-10-bgi-desktop-territory-exploration-design.md)
- 任務、收取與資料安全：[full-loop-contract-supplement.md](G:\Projects\BGi-Desktop\docs\superpowers\specs\2026-08-10-bgi-desktop-full-loop-contract-supplement.md)
- Lifecycle 狀態與復原：[mission-lifecycle-state-ownership.md](G:\Projects\BGi-Desktop\docs\superpowers\specs\2026-08-10-bgi-desktop-mission-lifecycle-state-ownership.md)
- 首次觸及的玩家可見成果：[text-placeholder-ui-state-and-error-spec.md](G:\Projects\BGi-Desktop\docs\superpowers\specs\2026-08-10-bgi-desktop-text-placeholder-ui-state-and-error-spec.md)
- 桌面 UI 與派遣：[bottom-ui-information-architecture.md](G:\Projects\BGi-Desktop\docs\superpowers\specs\2026-08-10-bgi-desktop-bottom-ui-information-architecture.md)、[mission-dispatch-confirmation-and-crew-configuration.md](G:\Projects\BGi-Desktop\docs\superpowers\specs\2026-08-10-bgi-desktop-mission-dispatch-confirmation-and-crew-configuration.md)
- UI 驗收邊界：[full-loop-acceptance-matrix.md](G:\Projects\BGi-Desktop\docs\superpowers\specs\2026-08-10-bgi-desktop-full-loop-acceptance-matrix.md)、[GODOT_TESTING.md](G:\Projects\BGi-Desktop\docs\operations\GODOT_TESTING.md)
