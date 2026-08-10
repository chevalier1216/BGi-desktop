# BGi Desktop：文字暫代 UI 操作狀態與錯誤訊息規格

> 日期：2026-08-10（Asia/Taipei）
> 狀態：可交給 coding 的獨立 UI 行為補充。
> 依據：`2026-08-10-bgi-desktop-full-loop-contract-supplement.md`。
> 範圍：無美術素材時，定義玩家可操作的狀態、禁止操作、文字鍵與驗收。
> 非範圍：不修改主規格、不修改 Godot、不設定報酬、機率、地盤門檻、取消成本或任何未定數值；未定內容一律為 `[PLACEHOLDER]`。

## 1. 共同 UI 規則

- 所有文字暫代 UI 均以「狀態 icon + 文字鍵對應的本地化字串」呈現；色彩與動畫只能補充，不能是唯一訊號。
- `MissionBoardEntry.board_state`、`MissionRunRecord.run_state`、`ClaimReceipt` 與 `TerritoryTouchReceipt` 是權威資料。UI 不得自行把倒數歸零、把任務標示為已收取，或自行增加人物。
- 每次玩家按下動作按鈕，UI 必須先顯示處理中狀態；只有存檔交易成功後才切換至成功狀態。資料仍未保存時，保留原狀態並顯示對應錯誤。
- 所有任務卡必顯示：任務 ID、時長、最低／最多人數、保底說明、額外範圍／機率說明與目前狀態。未定報酬／機率以 `[PLACEHOLDER]` 顯示，不能省略該欄位。
- 額外報酬為 0 時，文字必須使用「未取得額外獎勵」；不得顯示失敗、任務失敗或空手而回。
- 第一版不開放玩家取消已派遣任務。本文保留取消相關錯誤訊息，僅用於阻擋舊介面、快捷鍵或不合法請求，不能據此新增取消按鈕或改變既有任務狀態。

## 2. 文字鍵命名與回應封包

每次 UI 動作回應至少包含下列欄位；`message_key` 是玩家可見文字的唯一來源，`error_code` 供程式與 headless 自檢使用。

```text
UiActionResponse
  is_success: bool
  state_key: String
  message_key: String
  error_code: String
  primary_action_key: String
  affected_mission_run_id: String | empty
  affected_territory_id: String | empty
```

- 成功回應的 `error_code` 必須為空字串。
- 拒絕回應不得改寫權威資料；例外是「資料安全復原」將既有任務標為 `recovery_hold`，此時必須先保存復原理由。
- `primary_action_key` 不可指向禁止或不存在的功能；沒有可執行動作時填 `ui.action.view_details` 或空字串。

## 3. 操作狀態規格

### 3.1 任務可接受與派遣確認

| 項目 | 規格 |
| --- | --- |
| 前置 | `board_state=available`；任務未被刷新替換；玩家選取的人物均可用；人數符合 `min_assignees..max_assignees`；全域並行上限為 0 時不限制，其他值為 `[PLACEHOLDER]`。 |
| 可用操作 | 查看任務細節、選取／取消選取可用人物、確認派遣。 |
| 禁止操作 | 刷新該已被選取但尚未確認的任務不改變其資料；確認後不得重派同一任務；不可選取忙碌人物或重複人物。 |
| 成功狀態 | 建立並保存 `MissionRunRecord` 後轉為 `accepted`／`active`。 |
| 文字鍵 | `ui.mission.available.title`＝「可接受」、`ui.action.select_crew`＝「選擇人手」、`ui.action.dispatch`＝「確認派遣」、`ui.mission.dispatch_started`＝「已派出人手，任務開始。」 |
| 無美術驗收 | 純文字列表可選一項任務、選擇多人、顯示人數與團隊倍率；成功後任務顯示派遣中，對應人物不再出現在可選列表。 |

### 3.2 派遣中與離線完成

| 項目 | 規格 |
| --- | --- |
| 前置 | `MissionRunRecord.run_state=active`，且具有效 `mission_run_id`、`assigned_crew_ids`、`started_at_seconds`、`due_at_seconds`。 |
| 可用操作 | 查看指派人物、預計完成時間與剩餘時間；重啟後繼續讀取同一筆執行資料。 |
| 禁止操作 | 不可重派、收取、刷新替換、重新抽取結果或取消任務。 |
| 到期轉換 | `now_seconds >= due_at_seconds` 時，先固定並保存 `result_snapshot`，再轉為 `completed_pending_claim`。 |
| 文字鍵 | `ui.mission.active.title`＝「派遣中」、`ui.mission.remaining_time`＝「剩餘時間：{remaining_time}」、`ui.mission.complete_ready`＝「任務已完成，可收取成果。」 |
| 無美術驗收 | 用可注入時間完成 5 秒新手任務；程式重啟或重複檢查後，仍顯示同一任務、同一隊伍與同一結果識別。 |

### 3.3 完成待收取與已收取

| 項目 | 完成待收取 | 已收取 |
| --- | --- | --- |
| 前置 | `run_state=completed_pending_claim` 且已有固定 `result_snapshot`。 | `run_state=claimed` 且存在對應 `ClaimReceipt`。 |
| 可用操作 | 查看固定結果、收取。 | 查看收據與歷史結果。 |
| 禁止操作 | 不可重派、刷新替換、重骰額外報酬或取消。 | 不可再次收取、重骰、重派或取消。 |
| 成功狀態 | 收取交易保存後寫入唯一 `ClaimReceipt`，轉為 `claimed`。 | 維持 `claimed`。 |
| 文字鍵 | `ui.mission.claimable.title`＝「可收取」、`ui.action.claim`＝「收取成果」、`ui.reward.guaranteed`＝「保底獎勵：{guaranteed_reward}」、`ui.reward.bonus`＝「額外獎勵：{bonus_reward}」、`ui.reward.bonus_not_granted`＝「未取得額外獎勵」。 | `ui.mission.claimed.title`＝「已收取」、`ui.mission.claimed_at`＝「收取時間：{claimed_at}」、`ui.action.view_receipt`＝「查看收取紀錄」。 |
| 無美術驗收 | 連續觸發兩次收取，第二次只顯示同一張收據；額外為 0 時保底仍出現在收據與長期成長結果。 | 重啟後仍為已收取，不出現收取按鈕，人物恢復可用。 |

### 3.4 取消請求（第一版明確阻擋）

| 項目 | 規格 |
| --- | --- |
| 前置 | 玩家以舊介面、快捷鍵或不合法呼叫請求取消 `active` 或 `completed_pending_claim` 任務。 |
| 可用操作 | 查看任務與等待／收取後續流程。 |
| 禁止操作 | 取消任務、提前釋放人手、退回任務看板、重新抽取結果。 |
| 狀態結果 | 任務資料完全不變；不得建立取消收據。 |
| 文字鍵 | `ui.mission.cancel_unavailable.title`＝「目前無法取消」、`ui.mission.cancel_unavailable.body`＝「已派遣任務將持續至完成。完成後可收取成果。」 |
| 錯誤碼 | `mission_cancel_not_supported`。 |
| 無美術驗收 | 對派遣中與完成待收取任務送出取消請求，均回傳相同錯誤碼，隊伍、倒數、結果與收取資格不變。 |

### 3.5 手動刷新

| 項目 | 規格 |
| --- | --- |
| 前置 | `RefreshState.allowance=1`；看板存在至少一項可替換的 `available` 任務；新手固定 23 項目錄不適用替換。 |
| 可用操作 | 查看額度、下次可用時間、可替換數量；符合前置時執行手動刷新。 |
| 禁止操作 | 不可替換 `accepted`、`completed_pending_claim`、`claimed` 或新手固定任務；額度為 0 不可執行。 |
| 成功狀態 | 成功保存新看板與 `RefreshState` 後，額度改為 0；被替換項目保留追溯資料。 |
| 文字鍵 | `ui.refresh.title`＝「任務刷新」、`ui.refresh.allowance`＝「刷新額度：{allowance}/1」、`ui.refresh.next_available`＝「下次可用：{next_available_at}」、`ui.action.refresh`＝「刷新未接受任務」、`ui.refresh.success`＝「未接受任務已刷新。」 |
| 無美術驗收 | 以文字卡顯示 `0/1` 與 `1/1`；刷新後僅可用任務改變，已接受任務 ID 與執行資料保持不變。 |

### 3.6 地盤首次觸及與人物解鎖

| 項目 | 規格 |
| --- | --- |
| 前置 | 成功保存 `ClaimReceipt`；收取效果指向新 `territory_id`；該地盤尚無 `TerritoryTouchReceipt`。 |
| 可用操作 | 在收取結果中查看地盤變化、新人物與長期成長欄位；關閉結果後於地盤／人物區查看。 |
| 禁止操作 | 任務完成待收取、重看結果、背景切換或重複收取不得觸發觸及或人物增加。 |
| 成功狀態 | 建立並保存一張 `TerritoryTouchReceipt`，新增恰好 1 名初始可用人物。 |
| 文字鍵 | `ui.territory.first_touch.title`＝「觸及新地盤」、`ui.territory.first_touch.body`＝「已建立新的勢力據點。」、`ui.crew.unlocked`＝「新人物已加入：{crew_id}」、`ui.territory.progress`＝「地盤進度：{territory_progress}」。 |
| 無美術驗收 | 首次收取後人物總數增加 1；再次載入、重看或重複收取不再增加。三項長期成長欄位即使為 `[PLACEHOLDER]` 也持續可見。 |

### 3.7 未解鎖內容

| 項目 | 規格 |
| --- | --- |
| 前置 | 玩家查看尚未擁有的地盤、人物、背景、掛件、收藏或後續任務入口。 |
| 可用操作 | 查看名稱、解鎖條件與目前進度；可關閉說明。 |
| 禁止操作 | 不可派遣未解鎖人物、套用未擁有背景、放置未擁有掛件、接受尚未解鎖任務。 |
| 狀態結果 | 玩家存檔與看板資料均不變。 |
| 文字鍵 | `ui.locked.title`＝「尚未解鎖」、`ui.locked.requirement`＝「解鎖條件：{unlock_requirement}」、`ui.locked.progress`＝「目前進度：{current_progress}」。未定條件顯示 `[PLACEHOLDER]`。 |
| 無美術驗收 | 純文字入口保持可見但不可操作；按下時只顯示條件，無空白面板、無資料新增。 |

### 3.8 存檔讀取錯誤與安全復原

| 項目 | 規格 |
| --- | --- |
| 前置 | 讀取時發現不支援 `contract_version`、缺少必要 ID／時間／收取識別、資料損毀，或無法安全重建任務執行。 |
| 可用操作 | 重試讀取、查看不含個資的錯誤代碼與受影響任務 ID；未受影響區域可在資料完整時繼續查看。 |
| 禁止操作 | 不可自動補發報酬、直接標示已收取、直接刪除原存檔、建立新存檔覆寫原檔，或從 UI 推斷遺失資料。 |
| 狀態結果 | 可識別的問題任務保存為 `recovery_hold` 並保存 `recovery_reason`；無法驗證整份存檔時停在唯讀錯誤頁。 |
| 文字鍵 | `ui.save.load_error.title`＝「無法安全讀取存檔」、`ui.save.load_error.body`＝「資料尚未被變更。請重試讀取或保留錯誤代碼供檢查。」、`ui.action.retry_load`＝「重試讀取」、`ui.mission.recovery_hold`＝「此任務等待安全復原。」 |
| 錯誤碼 | `save_contract_unsupported`、`save_required_field_missing`、`save_data_corrupted`、`mission_recovery_hold`。 |
| 無美術驗收 | 提供缺欄位與不合法版本的測試資料；不得產生新報酬、收據、地盤觸及或人物。可識別任務保持可追溯，無法驗證的資料不被覆寫。 |

## 4. 共通錯誤訊息對照

| 錯誤碼 | 玩家可見文字鍵 | 顯示文字 | 保持不變的資料 |
| --- | --- | --- | --- |
| `crew_count_below_min` | `ui.dispatch.error.crew_count_below_min` | 「人手不足，請再選擇可用人物。」 | 任務看板、人物狀態、刷新額度。 |
| `crew_count_above_max` | `ui.dispatch.error.crew_count_above_max` | 「人手超過此任務可派上限。」 | 同上。 |
| `crew_busy` | `ui.dispatch.error.crew_busy` | 「選擇的人物正在執行其他任務。」 | 同上。 |
| `crew_duplicate` | `ui.dispatch.error.crew_duplicate` | 「同一人物不可重複派遣。」 | 同上。 |
| `global_cap_reached` | `ui.dispatch.error.global_cap_reached` | 「目前同時執行任務數已達上限。」 | 目前參數為 0 時不應出現。 |
| `refresh_allowance_unavailable` | `ui.refresh.error.allowance_unavailable` | 「目前沒有可用刷新額度。」 | 任務看板與刷新額度。 |
| `no_refreshable_replacement` | `ui.refresh.error.no_replacement` | 「目前沒有可替換的未接受任務。」 | 同上。 |
| `claim_save_pending` | `ui.claim.error.save_pending` | 「成果尚未安全保存，請稍後再試。」 | 固定結果、人物與所有長期成長資料。 |
| `mission_cancel_not_supported` | `ui.mission.cancel_unavailable.body` | 「已派遣任務將持續至完成。完成後可收取成果。」 | 任務、隊伍、時計與結果。 |
| `save_contract_unsupported` | `ui.save.load_error.title` | 「此存檔版本目前無法安全讀取。」 | 原存檔。 |
| `save_required_field_missing` | `ui.save.load_error.title` | 「存檔缺少必要資料，無法安全繼續。」 | 原存檔與未驗證結果。 |
| `save_data_corrupted` | `ui.save.load_error.title` | 「存檔資料無法驗證，未進行任何變更。」 | 原存檔。 |
| `mission_recovery_hold` | `ui.mission.recovery_hold` | 「此任務等待安全復原。」 | 問題任務以外的已驗證資料。 |

## 5. 無美術整合驗收

1. 以純文字任務卡完成「可接受 → 派遣中 → 可收取 → 已收取」；每一狀態都有唯一主要動作或明確無動作原因。
2. 多人派遣、人物忙碌、人數不足／超限、額外獎勵為 0、刷新額度為 0、未解鎖項目與取消請求都呈現對應文字鍵與錯誤碼。
3. 離線完成、重複收取與重複地盤觸及，均不改變既有 `result_id`、`ClaimReceipt` 或已解鎖人物數。
4. 存檔讀取錯誤時，UI 不生成任何報酬、收據、人物或新存檔；只能重試或呈現可追溯的安全復原狀態。
5. 關閉所有動態效果或完全沒有背景／掛件素材時，以上操作與驗收仍可完成。

## 6. 針對既有補充規格的審核結果

此次審核確認：

- 「取消」已被限制為拒絕請求，與完整一輪補充規格中「第一版不需要玩家取消任務」一致。
- `completed_pending_claim` 是唯一可收取狀態；結果快照先固定、收據後建立，避免 UI 把尚未保存的成果視為已領取。
- 地盤首次觸及被限制在成功收取之後，背景提示與未解鎖內容不具觸發權。
- 存檔讀取錯誤採不覆寫、不中獎的安全邊界；對可識別任務以 `recovery_hold` 保留追溯。
- 本文件未新增任何報酬、機率、取消成本、門檻或素材採用決策；相關內容均維持 `[PLACEHOLDER]` 或既有已核准參數。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 日期時間 | 2026-08-10 Asia/Taipei |
| 類型 | 設計補充／文字暫代 UI 狀態與錯誤訊息 |
| 目標 | 定義任務、刷新、地盤、未解鎖與存檔讀取錯誤的可操作狀態、玩家可見文字鍵與無美術驗收。 |
| 檔案相對位置 | `docs/superpowers/specs/2026-08-10-bgi-desktop-text-placeholder-ui-state-and-error-spec.md` |
| 行號 | 1–176；共同規則 9–16、操作狀態 39–127、錯誤對照 129–145、無美術驗收 147–153、設計審核 155–163。 |
| 變更摘要 | 新增八組操作狀態、共通錯誤對照、文字鍵、取消明確阻擋規則與無美術整合驗收。 |
| 驗證結果 | 依 full-loop contract supplement 對照；取消未被擴張為功能，所有未定數值維持 `[PLACEHOLDER]`；未改主規格、Godot 或素材。 |
| 預期 Git commit | 待日誌分支提交 |
