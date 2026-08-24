# BGi Desktop：完整一輪遊玩資料契約與文字暫代流程補充

> 日期：2026-08-10（Asia/Taipei）
> 狀態：可交給 coding 的補充規格；不修改既有 territory exploration 主規格。
> 範圍：把目前已核准的任務、離線完成、收取、地盤觸及與人物解鎖，整理為可序列化且可驗收的最小契約。
> 非範圍：不指定報酬、機率、地盤門檻、任務池抽取權重或美術素材；它們一律維持 `[PLACEHOLDER]`。本文件也不把完整一輪或 QA 當成現行 coding 小目標的中止門檻。

## 1. 唯讀盤點結論

目前程式已有可用的局部基礎：固定 23 項新手任務目錄、多人派遣規則、任務時計快照、結果鎖定、刷新額度、未接受任務替換、地盤首次觸及與單一人物解鎖，以及地盤長期成長欄位的文字暫代模型。

尚未形成完整一輪的原因，是上述單元尚未由一個可保存的任務實例串起來，且桌面主畫面仍只列出任務 ID、時長與是否接受。以下契約補上串接邊界；coding 可沿既有小目標逐項接入，不需等待所有項目完成。

| 優先 | 缺口 | 最小處理工作 | 完成判定 |
| --- | --- | --- | --- |
| P0 | 任務時計、結果鎖定與派遣資料彼此分離 | 建立 `MissionRunRecord`，作為已接受任務的唯一可保存實例 | 重啟後能指出同一任務、同一隊伍、同一開始／結束時間與同一結果識別。 |
| P0 | 結果僅有文字 placeholder，沒有收取冪等邊界 | 建立 `ClaimReceipt` 與一次性收取流程 | 重複點擊、重啟或載入舊存檔，不會重複套用任何保底、額外、地盤或解鎖效果。 |
| P0 | 刷新額度已有單元，未納入存檔與畫面 | 將額度、最後補充檢查時間與刷新結果寫入玩家存檔 | 每 6 小時最多補成 1 額度；只替換未接受任務；無額度或無可替換項目有明確原因。 |
| P1 | 地盤首次觸及與人物解鎖尚未綁定收取交易 | 建立 `TerritoryTouchReceipt`，由有效收取結果觸發 | 同一地盤只首次解鎖 1 名人物；再次收取或載入不重複增加人物。 |
| P1 | 主畫面未呈現可操作循環 | 以文字暫代完成任務卡、派遣、倒數、收取與長期成長的狀態切換 | 不需任何美術素材，仍可看見下一個可行動操作及其阻擋原因。 |
| P2 | 背景／掛件與動態插槽尚未進入存檔聚合 | 待核心循環可串接後，再接入既有背景、掛件與靜態備援資料 | 不改變任務、報酬、地盤或人物數值；背景切換不改寫掛件資料。 |

## 2. 存檔總包與共通原則

所有第一版狀態必須可轉為純資料並由本機存檔復原；不得保存 Node、callback、機器絕對路徑或僅存在記憶體的隨機狀態。Steam Cloud 是後續整合，不改變本契約。

```text
PlayerSaveEnvelope
  contract_version: "full_loop_contract_v1"
  crew_by_id: Dictionary<CrewId, CrewRecord>
  mission_board: Array<MissionBoardEntry>
  mission_runs_by_id: Dictionary<MissionRunId, MissionRunRecord>
  refresh_state: RefreshState
  claim_receipts_by_id: Dictionary<ClaimReceiptId, ClaimReceipt>
  territory_state_by_id: Dictionary<TerritoryId, TerritoryState>
  territory_touch_receipts_by_id: Dictionary<TerritoryId, TerritoryTouchReceipt>
  progression_summary: ProgressionSummary
```

- 寫入順序：先建立或更新任務／收取交易資料，再保存 `PlayerSaveEnvelope`；存檔成功後才讓 UI 顯示完成的動作結果。
- 讀取順序：先驗證 `contract_version` 與必要 ID，再重建任務狀態；缺少單一非關鍵展示欄位時可套用安全預設，缺少任務 ID、人物 ID、收取識別或時間欄位時不得自動補發報酬。
- 每個 ID 均為穩定 ASCII 字串。`mission_template_id` 描述任務目錄；`mission_run_id` 描述一次已接受執行；兩者不得混用。
- 計時以注入的 `now_seconds` 作為唯一輸入，介面只能顯示衍生倒數。這使離線完成與 headless 自檢能使用同一條邏輯。
- 異常大幅時間跳躍依既有 `[PLACEHOLDER]` 安全上限處理；上限觸發時保留原始執行與結果資料，不可重骰或自動收取。

## 3. 任務看板與執行資料契約

### 3.1 `MissionBoardEntry`

任務看板只保存「玩家尚可選擇的任務」與其公開資訊。已接受任務的動態資料只存在 `MissionRunRecord`。

| 欄位 | 必填 | 說明 |
| --- | --- | --- |
| `mission_template_id` | 是 | 任務目錄的穩定 ID；新手任務固定為 `starter_01` 至 `starter_23`。 |
| `board_state` | 是 | `available`、`accepted`、`completed_pending_claim`、`claimed`、`replaced` 之一。 |
| `duration_seconds` | 是 | 已核准的新手時長，或後續任務的已設定時長。 |
| `min_assignees`、`max_assignees` | 是 | 人數檢核邊界；實際數值由任務資料提供。 |
| `guaranteed_reward_display` | 是 | 可公開顯示的保底報酬描述；數量／類別未定時使用 `[PLACEHOLDER]`。 |
| `bonus_reward_display` | 是 | 額外報酬範圍與機率描述；可為 0，數值未定時使用 `[PLACEHOLDER]`。 |
| `active_mission_run_id` | 條件必填 | 當 `accepted` 或 `completed_pending_claim` 時必填；其餘狀態為空。 |

### 3.2 `MissionRunRecord`

`MissionRunRecord` 是 P0 首要資料契約。它凍結一次派遣所需的身份、隊伍、時計、倍率與結算狀態，避免刷新、重啟或日後調整模板後改寫既有任務。

| 欄位 | 必填 | 說明 |
| --- | --- | --- |
| `mission_run_id` | 是 | 每次成功接受任務新建一次，永不重用。 |
| `mission_template_id` | 是 | 對應 `MissionBoardEntry`。 |
| `assigned_crew_ids` | 是 | 去重後的人物 ID 陣列；長度必須介於模板的最低／最多人數。 |
| `crew_reward_multiplier` | 是 | 派遣確認當下已明示的團隊報酬倍率；實際公式維持 `[PLACEHOLDER]`。 |
| `started_at_seconds`、`due_at_seconds` | 是 | 執行開始與預計完成時間；`due_at_seconds = started_at_seconds + duration_seconds`。 |
| `run_state` | 是 | `active`、`completed_pending_claim`、`claimed`、`recovery_hold` 之一。 |
| `result_snapshot` | 條件必填 | 只有完成後存在；其中含完成時已解析的 `ClaimEffectDescriptor`；一經寫入不得改變。 |
| `claim_receipt_id` | 條件必填 | 只有 `claimed` 時存在，指向唯一收取收據。 |
| `recovery_reason` | 條件必填 | 只有 `recovery_hold` 時存在；不可用此狀態產生或收取結果。 |

狀態轉換僅允許：

```text
available --成功派遣--> active --now >= due_at--> completed_pending_claim --成功收取--> claimed
active --資料無法安全復原--> recovery_hold
recovery_hold --修復後仍能識別原 run--> active 或 completed_pending_claim
```

- `active` 期間，所有 `assigned_crew_ids` 對應人物皆為派遣中，不能加入另一任務。
- `completed_pending_claim` 時，必須先建立固定的 `result_snapshot`（含已解析的 `ClaimEffectDescriptor`），並安全保存原派遣人物恢復可用，才允許 UI 顯示收取按鈕。人物恢復可用不代表報酬或任何長期效果已提交；後續收取保存失敗不得把人物狀態回退為派遣中。
- `claimed` 任務保留作歷史／教學進度依據；不得重新回到可派遣狀態。
- 第一版不需要玩家取消任務。既有取消／釋放服務不得被視為產品流程授權，除非日後另行核准。

### 3.3 `result_snapshot` 與 `ClaimReceipt`

結果快照的職責是呈現；收取收據的職責是保證結果只套用一次。兩者均不得把「額外為 0」寫成失敗、空手而回或任務失敗。

| 資料 | 必填欄位 | 不變性 |
| --- | --- | --- |
| `result_snapshot` | `result_id`、`mission_run_id`、`resolved_at_seconds`、`guaranteed_reward`、`bonus_reward`、`bonus_outcome`、`claim_effect_descriptors` | `bonus_outcome` 只能是 `granted` 或 `not_granted`；完成任務一定有保底。結果與效果描述符首次建立後不可重算。 |
| `ClaimReceipt` | `claim_receipt_id`、`mission_run_id`、`result_id`、`claimed_at_seconds`、`applied_effect_ids`、`effect_descriptors` | 同一 `mission_run_id` 最多一張；`effect_descriptors` 是結果快照內已固定描述符的保存引用或等值副本。重複請求回傳既有收據，不得再次套用效果。 |

`applied_effect_ids` 僅記錄效果識別，不以本文件決定數值：例如 `territory_progress:[PLACEHOLDER]`、`collection:[PLACEHOLDER]`、`decoration:[PLACEHOLDER]`、`currency:[PLACEHOLDER]`。若某效果不適用，使用空集合；不可憑空補出報酬。

`ClaimEffectDescriptor` 是完成時已解析、在進入 `completed_pending_claim` 前即隨固定結果保存的效果橋接資料。收取及讀檔只能讀取此固定資料，不得由當前任務設定、掉落表或內容對照重新推導。

P1 已核准的描述符為：

- `territory_first_touch`：含 `territory_id`、`character_id`。第一次成功套用時建立該地盤的 `TerritoryTouchReceipt`、將地盤由未涉足改為已觸及，並解鎖已固定的 1 名人物；已套用時為 no-op。
- `collectible_grant`：含 `collectible_id`、`quantity`。`unique` 未擁有時取得，已擁有時不重抽、不替代；`stackable` 以固定數量只增加一次；`series` 沿用相同收取契約，系列歸屬僅為 metadata。

場景道具與場景組的 `collectible_grant` 僅建立所有權，不會自動顯示、套用或放置。任務對照、掉落表、機率、數量、用途、系列獎勵與完整放置互動均不在本次範圍。

### 3.4 P1 固定 `mission_template_id` 效果對照

下列 effect 必須在相應 `mission_template_id` 完成時解析，並與該次 `result_snapshot` 一併保存；`ClaimReceipt`、重試與讀檔只使用保存後的描述符。`starter_18`–`starter_23` 是 canonical tutorial mission identities，不以 `T18`–`T23` 教學標籤作為資料鍵。

| `mission_template_id` | 已固定 `ClaimEffectDescriptor` |
| --- | --- |
| `starter_18` | `territory_first_touch { territory_id: territory_02, character_id: character_06 }` |
| `starter_19` | `collectible_grant { collectible_id: collectible.r01.goldbar_001, quantity: 1 }` |
| `starter_20` | `collectible_grant { collectible_id: collectible.r01.gift_001, quantity: 1 }` |
| `starter_21` | `collectible_grant { collectible_id: collectible.r01.neon_001, quantity: 1 }` |
| `starter_22` | `collectible_grant { collectible_id: collectible.r01.vehicle_001, quantity: 1 }` |
| `starter_23` | `collectible_grant { collectible_id: collectible.r01.cityset_001, quantity: 1 }` |

`starter_19` 的 Unique 重複處理不另給一份；`starter_20` 的 quantity 只界定該任務本身，不推導未來 gift 來源或 Stackable 用途；`starter_21` 不產生 Series 完成獎勵；`starter_22`、`starter_23` 維持 ownership-only。未列在本表的 tutorial／正式任務不因此取得 mapping。`starter_01:100 → territory_02` 仍僅是 implementation/test fixture，不是產品內容來源。

## 4. 刷新、地盤與人物解鎖契約

### 4.1 `RefreshState`

| 欄位 | 說明 |
| --- | --- |
| `allowance` | 整數，範圍固定為 `0..1`。 |
| `last_refill_check_seconds` | 最後一次補充檢查時間。 |
| `next_available_at_seconds` | 由前兩欄導出的展示值；不得獨立成為權威資料。 |

- 任何刷新請求先以 `now_seconds` 補充額度；滿 6 小時只補到 1，不可累積多次額度。
- 只允許替換 `board_state=available` 的任務；`accepted`、`completed_pending_claim` 與 `claimed` 都不可替換。
- 新手固定 23 項目錄不可因刷新改變。後續看板替換時，每個被替換項目必須保留 `replaced` 歷史或等值追溯資料，避免 ID、收取或教學進度誤指向新項目。

### 4.2 `TerritoryState` 與 `TerritoryTouchReceipt`

| 資料 | 必填欄位 | 規則 |
| --- | --- | --- |
| `TerritoryState` | `territory_id`、`territory_progress`、`exploration_collection_count`、`environment_decoration_owned_count` | 三個長期成長值可先以 `[PLACEHOLDER]` 顯示，但欄位與 ID 必須存在。 |
| `TerritoryTouchReceipt` | `territory_id`、`source_claim_receipt_id`、`touched_at_seconds`、`unlocked_crew_id` | 同一 `territory_id` 只建立一次。首次觸及新地盤必須解鎖恰好 1 名新人物。 |

- 地盤觸及只能由已成功建立的 `ClaimReceipt` 及其已固定 `territory_first_touch` 描述符觸發；任務完成待收取、重看結果或背景切換不能觸發。
- 解鎖人物時必須把新人物完整寫入 `crew_by_id`，初始狀態為可用；不能只遞增一個人數計數器。
- 背景、收藏與環境布置可由有效收取效果解鎖，但它們的所有權與顯示資料不得充當地盤首次觸及的唯一證據。

## 5. 文字暫代 UI 流程與阻擋理由

此節是本次盤點後立即完成的安全小目標：先定義無美術也能串接的 UI 狀態，避免 coding 只完成資料而無法操作驗收。第一版只需文字、按鈕、狀態 icon 與既有面板；不要求新素材或動態效果。

| 畫面節點 | 必顯示內容 | 玩家動作 | 成功後 UI | 不能執行時 UI |
| --- | --- | --- | --- |
| 任務列表 | 任務 ID、時長、最低／最多人數、保底、額外範圍／機率、目前狀態 | 選取可用任務 | 開啟派遣選擇 | 已接受或已收取項目只可查看，不提供派遣。 |
| 派遣選擇 | 可用人物、已選人數、最低／最多人數、團隊倍率 | 確認派遣 | 任務改為派遣中、人物改為派遣中、倒數開始 | 顯示 `crew_count_below_min`、`crew_count_above_max`、`crew_busy`、`crew_duplicate` 或 `global_cap_reached`。目前全域上限為 0 時，不顯示阻擋。 |
| 派遣中卡片 | 指派人物、預計完成時間、剩餘時間 | 查看 | 到期時改為可收取 | 不提供刷新或重派。 |
| 可收取卡片 | 固定保底、已固定的額外結果；額外為 0 時顯示「未取得額外獎勵」；原派遣人物已可再派遣 | 收取 | 顯示本次已套用效果、地盤／收藏／布置變化與人物解鎖（如有） | 若存檔交易未完成，保留可收取狀態與既有的人物可用狀態並顯示 `claim_save_pending`；不可假定已領取。 |
| 刷新區 | 額度 `0/1`、下次可用時間、可替換數量 | 手動刷新 | 只更新可用任務並扣除額度 | 顯示 `refresh_allowance_unavailable` 或 `no_refreshable_replacement`。 |
| 地盤／人物區 | 目前地盤 ID、三個長期成長欄位、人物總數與可用／忙碌數 | 查看細節 | 首次觸及時顯示新人物已加入 | 重複觸及僅顯示既有地盤狀態，不再顯示解鎖。 |

顯示優先序：同一時間若「可收取」「新地盤觸及／人物解鎖」「背景提示」同時產生，先完成收取結果面板，再依序顯示人物解鎖與背景提示。背景提示不能覆蓋收取確認或阻斷收取交易。

## 6. 最小驗收案例與交付順序

### P0-A：任務實例與離線完成

1. 對一項新手任務派遣符合最低／最多人數的隊伍，存檔後重啟。
2. 以 `now_seconds >= due_at_seconds` 載入，任務只轉為 `completed_pending_claim` 一次，且 `result_snapshot.result_id` 固定；原派遣人物在完成保存後恢復可用。
3. 再次重啟或再次檢查時計，結果 ID、保底與額外結果均不改變。

### P0-B：收取冪等與刷新邊界

1. 對同一完成任務連續執行兩次收取；第二次回傳同一 `ClaimReceipt`，任何效果只出現一次。
2. 額外報酬為 0 時仍可收取保底，UI 使用「未取得額外獎勵」。
3. 對可刷新看板在 6 小時前、6 小時後、連續 12 小時未開啟的情況各檢查一次；額度最高均為 1，且已接受項目未被替換。

### P1：地盤與人物

1. 有效收取已固定的 `territory_first_touch` 描述符時，建立一張 `TerritoryTouchReceipt` 並加入其已固定的 1 名可用人物。
2. 對同一任務重複收取、重新載入、或再觸及同一地盤，人物數不再增加。既有 `starter_01:100 → territory_02` 僅可作測試 fixture，不是產品內容對照。
3. 文字暫代 UI 可看見地盤長期成長欄位與人物可用／忙碌數，即使所有數值仍為 `[PLACEHOLDER]`。

建議交付順序：`P0-A` → `P0-B` → 文字暫代 UI → `P1`。這是後續完整一輪的整合順序，並不要求中止既有 coding 小目標或提前建立 `BGi-desktop_QA`。

## 7. 現有單元接點對照

本節是補充文件完成後的下一個安全設計小目標：確認既有單元可被保留，並明示它們接入完整循環時各自只負責的界線。此表不要求重構或修改既有程式。

| 現有單元 | 可保留責任 | 接入時需要由上層補足的資料 |
| --- | --- | --- |
| `starter_mission_catalog.gd` | 產出固定 `starter_01`–`starter_23` 及已核准時長分布 | 把目錄條目轉成 `MissionBoardEntry`；新手刷新不替換目錄。 |
| `persistent_mission_assignment_coordinator.gd` 與 `dispatch_rules.gd` | 檢核人物可用性、去重與多人派遣 | 成功後建立 `MissionRunRecord`，並保存隊伍、倍率、開始／結束時間。 |
| `mission_execution_snapshot.gd` 與 `mission_execution_clock.gd` | 保存與復原時計、判斷到期 | 以 `mission_run_id` 關聯；不可只用 `task_id` 當作一次執行的識別。 |
| `mission_completion_result_lock.gd` | 在完成後只建立一次結果快照 | 補齊 `result_id`、`bonus_outcome` 與對應 `mission_run_id`；不在此單元套用收取效果。 |
| `mission_refresh_allowance.gd` 與 `mission_refresh_service.gd` | 每 6 小時補成最多 1 額度，且只替換未接受項目 | 將 `RefreshState` 納入存檔，並把 service 結果映射到文字暫代 UI。 |
| `territory_first_touch_unlock.gd` | 對單一地盤提供首次觸及／單次解鎖判斷 | 只從成功 `ClaimReceipt` 呼叫，並把新人物完整寫入 `crew_by_id`。 |
| `territory_progress_model.gd` | 提供三項長期成長欄位的展示資料 | 由已收取效果更新；數值未定時維持 `[PLACEHOLDER]`。 |
| `desktop_shell.gd` | 目前桌面面板與初始人物／任務文字清單 | 讀取上述聚合存檔，顯示任務狀態、阻擋原因、倒數、收取與地盤／人物變化。 |

不得以任一 UI 呈現結果作為收取成功的依據；唯一權威證據仍是已保存的 `ClaimReceipt` 與其 `applied_effect_ids`。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 日期時間 | 2026-08-10 Asia/Taipei |
| 類型 | 設計補充／資料契約與 UI 流程 |
| 目標 | 在不改動混入 0.7 內容的主規格前提下，補足完整一輪遊玩的任務、收取、刷新、地盤與人物解鎖邊界。 |
| 檔案相對位置 | `docs/superpowers/specs/2026-08-10-bgi-desktop-full-loop-contract-supplement.md` |
| 行號 | 1–192；核心契約 23–125、文字暫代 UI 127–140、驗收與順序 142–162、既有單元接點 164–179。 |
| 變更摘要 | 新增存檔總包、任務實例、結果／收取冪等、刷新、地盤首次觸及、文字暫代 UI、錯誤碼、最小驗收案例與既有單元接點；報酬與機率保留 `[PLACEHOLDER]`。 |
| 驗證結果 | 唯讀比對既有主規格、基礎實作計畫、動態分層研究與現有任務／刷新／地盤單元；未改 Godot、素材、混入 0.7 的主規格或既有程式。 |
| 預期 Git commit | 待日誌分支提交 |
