# BGi Desktop：完整一輪遊玩驗收矩陣

> 日期：2026-08-10（Asia/Taipei）
> 狀態：後續完整一輪里程碑的驗收映射；不阻斷現行 coding 小目標。
> 依據：territory exploration 主規格的完整一輪條文、完整一輪資料契約補充、文字暫代 UI 狀態與錯誤訊息規格、`docs/operations/GODOT_TESTING.md`。
> 範圍：將八項已核准循環要求映射到資料服務、文字 UI、可視化操作、headless／手動證據與缺少接線。
> 非範圍：不建立 `BGi-desktop_QA`、不設定報酬／機率／門檻／倍率數值、不改主規格、Godot 或素材；未定內容維持 `[PLACEHOLDER]`。

## 1. 使用方式與通過門檻

- 此矩陣的「現有證據」只證明個別服務已有 headless 測試或已存在資料模型，不能宣稱完整一輪已通過。
- 「尚缺接線」必須在完整一輪整合前逐項清除；八列均具可追溯的 headless 與手動文字暫代證據，才可聲明完整一輪通過。
- 通過後才可建立 `BGi-desktop_QA`；在此之前，既有 coding 可持續以小目標推進，不需等待矩陣完成。
- 每次整合驗收都需保留：測試版本／commit、headless 指令與結束碼、文字走查紀錄、任務 ID、人物 ID、地盤 ID、`result_id`、收取前後存檔狀態及已知限制。不得藉此記錄或推導新的報酬／機率數值。

## 2. 八項循環要求驗收矩陣

| # | 已核准要求 | 資料服務／權威資料 | 文字 UI 與可視化操作 | Headless 證據 | 手動文字暫代證據 | 尚缺接線／通過條件 |
| ---: | --- | --- | --- | --- | --- | --- |
| 1 | 初始 5 名相同小弟；每名不可同時兩任務；任務支援最低／最多人數。 | `GameState`、`MissionAssignmentState`、`DispatchRules`、`PersistentMissionAssignmentCoordinator`；完整一輪以 `MissionRunRecord.assigned_crew_ids` 為已接受任務快照。 | 任務卡顯示最低／最多人數；派遣面板只列可用人物，顯示已選人數與團隊倍率；忙碌／重複／人數錯誤顯示對應文字鍵。 | 已有 `game_state_test.gd`、`dispatch_rules_test.gd`、`mission_assignment_state_test.gd`、`persistent_mission_assignment_coordinator_test.gd`。 | 新存檔顯示 5 人；派出符合人數的多人隊伍後，這些人改為派遣中；嘗試重複指派同一人物被拒絕。 | 將派遣成功連接到 `MissionRunRecord` 存檔與 UI 回應封包；任務專屬 `min_assignees`／`max_assignees` 仍為 `[PLACEHOLDER]`。 |
| 2 | 每 6 小時取得一次刷新額度、上限 1、只刷新未接受任務。 | `MissionRefreshAllowance`、`MissionRefreshService`、`RefreshableMissionFilter`、`MissionRefreshReplacement`；完整一輪以 `RefreshState` 保存額度與時間。 | 刷新區顯示 `0/1` 或 `1/1`、下次可用時間與可替換數量；只提供「刷新未接受任務」操作。 | 已有 `mission_refresh_allowance_test.gd`、`mission_refresh_service_test.gd`、`refreshable_mission_filter_test.gd`、`mission_refresh_replacement_test.gd`。 | 在 6 小時前顯示無額度；滿 6 小時後顯示 `1/1`；刷新後僅可用任務變化，已接受任務保留。 | 將 `RefreshState` 寫入／讀回 `PlayerSaveEnvelope`；新手固定 23 項目錄不可替換，後續任務替換資料與規則仍為 `[PLACEHOLDER]`。 |
| 3 | 關閉程式後任務持續完成，完成時結果固定，原派遣人物恢復可用。 | `MissionExecutionClock`、`MissionExecutionSnapshot`、`MissionExecutionSnapshotCollection`、`MissionCompletionResultLock`；完整一輪以 `MissionRunRecord` 與 `result_snapshot` 聚合。 | 派遣中卡顯示預計完成與剩餘時間；重啟後顯示同一任務；到期後改為可收取，且原派遣人物可再選。 | 已有 `mission_execution_clock_test.gd`、`mission_execution_snapshot_test.gd`、`mission_execution_snapshot_collection_test.gd`、`mission_completion_result_lock_test.gd`。 | 派遣 5 秒新手任務、關閉程式、待到期後重啟；任務變為可收取，重開／重看後 `result_id` 不變，原派遣人物可加入其他任務。 | 建立以 `mission_run_id` 為鍵的持久執行聚合；完成交易須同時保存固定結果、待收取狀態與人物可用狀態。 |
| 4 | 任務卡明示保底報酬、額外範圍與機率，完成必有保底。 | `MissionRewardDisclosureModel`、`MissionBoardEntry.guaranteed_reward_display`、`bonus_reward_display`、`result_snapshot.guaranteed_reward`。 | 任務卡與結果卡均顯示保底、額外範圍與機率；未定內容顯示 `[PLACEHOLDER]`，不可隱藏欄位。 | 已有 `mission_reward_disclosure_model_test.gd`。 | 開啟任務詳細資料與收取結果，兩處均可讀到保底與額外欄位；完成結果至少有一項保底。 | 將揭露模型接入任務卡與固定結果快照；實際報酬類別、數量、範圍及機率仍為 `[PLACEHOLDER]`。 |
| 5 | 額外報酬可為 0，不能使用失敗或空手而回。 | `result_snapshot.bonus_outcome` 僅允許 `granted`／`not_granted`；`ClaimReceipt` 確保保底與效果只套用一次。 | 當額外為 0 時，顯示「未取得額外獎勵」與保底成果；不顯示失敗、空手而回或任務失敗。 | `mission_reward_disclosure_model_test.gd` 已覆蓋零額外揭露；完整收取冪等測試尚缺。 | 以測試資料完成一筆額外為 0 的任務，收取後保底存在；重複點擊收取只回傳同一收據。 | 建立 `ClaimReceipt` 與 `result_snapshot.result_id` 的整合測試；零額外的機率與數量規則維持 `[PLACEHOLDER]`。 |
| 6 | 地盤、探索收藏、環境布置有可見長期成長。 | `TerritoryProgressModel`、`TerritoryState`、`ClaimReceipt.applied_effect_ids`；完整背景、前景掛件、場景物件／套件與純收藏的所有權維持獨立資料，不作為地盤唯一證據。 | 地盤／人物區持續顯示地盤進度、探索收藏數與環境布置擁有數；未取得內容以文字 `[PLACEHOLDER]` 呈現。 | 既有欄位測試保留；另驗證有效保存收據才可推進，以及已核准的收藏／布置操作不會重複建立資料。 | 收取後可看見三項長期成長欄位及本次已套用效果；以有效測試資料完成已核准的收藏或布置操作；切換背景、套件或關閉動態不改變所有權。 | 成長公式、門檻、具體 item ID 與實際數值維持 `[PLACEHOLDER]`；不得以 UI 操作、背景／套件切換或未保存暫存資料推進地盤、收藏或布置。 |
| 7 | 首次觸及新地盤解鎖 1 名新人物。 | `TerritoryFirstTouchUnlock`、`TerritoryTouchReceipt`、`crew_by_id`；來源必須是已保存的 `ClaimReceipt`。 | 收取結果依序顯示「觸及新地盤」與「新人物已加入」；人物區增加 1 名可用人物；重複觸及不再提示解鎖。 | 已有 `territory_first_touch_unlock_test.gd`，覆蓋首次、重複與不同地盤。 | 以一筆有效收取第一次觸及新地盤，人物從 5 增至 6；重啟、重看、重複收取後仍為 6。 | 把首次觸及服務接入成功 `ClaimReceipt`，並新增完整人物資料而非只增加計數；新人物數值／外觀仍在既有範圍或 `[PLACEHOLDER]`。 |
| 8 | 新手任務先驗證等待時間與功能。 | `StarterMissionCatalog`、`TutorialTaskProgression`、`TutorialMissionCompletionCoordinator`、時計與派遣服務。 | 文字 UI 依固定 `starter_01`–`starter_23` 順序呈現目前任務；派遣、等待、完成與收取均可被走查。 | 已有 `starter_mission_catalog_test.gd`、`tutorial_task_progression_test.gd`、`tutorial_mission_completion_coordinator_test.gd`、`tutorial_mission_lifecycle_test.gd`。 | 至少走完 5 秒任務的派遣→等待→完成→收取；完成待收取時可再派原人物，但下一教學步與成果效果仍待收取成功才推進。 | 現有教學完成流程須改接到「結果固定並釋放人物、收取後才推進成果與教學」流程；23 項全部完成與中斷復原的整合驗收尚缺。 |

## 3. 必備證據格式

### Headless 證據

每一列完成整合後，必須使用 Godot headless 執行對應測試，並保留：

```text
test_id: [PLACEHOLDER]
commit: [PLACEHOLDER]
command: godot --headless --path <project> --script <test>
exit_code: 0
covered_requirement_ids: [1..8]
input_clock_seconds: [PLACEHOLDER]
mission_template_id: [PLACEHOLDER]
mission_run_id: [PLACEHOLDER]
result_id: [PLACEHOLDER]
claim_receipt_id: [PLACEHOLDER]
territory_id: [PLACEHOLDER]
```

既有單元測試可作為前置證據；完整一輪須另有一支整合測試或等效測試組，能以同一份可控制時間的測試資料連續覆蓋八列。測試資料的報酬與機率不得在此文件定值。

### 手動文字暫代證據

每次走查以文字紀錄或截圖附上以下欄位；在沒有美術素材時，文字 UI 本身即是可視化操作證據。

| 欄位 | 要求 |
| --- | --- |
| 版本識別 | commit 或可追溯建置識別。 |
| 起始狀態 | 5 名人物 ID 與狀態、任務 ID、刷新額度、地盤 ID、存檔版本。 |
| 操作序列 | 玩家按下的文字動作鍵及 UI 回應的 `message_key`／`error_code`。 |
| 等待與重啟 | 開始、到期、關閉／重啟、讀取後的狀態及 `result_id`。 |
| 收取與長期成長 | `ClaimReceipt`、保底／額外顯示、額外為 0 的文案、地盤三欄、收藏／布置變化。 |
| 首次觸及 | `territory_id`、新增人物 ID、重複觸及後人物總數。 |
| 例外 | 刷新不足、未解鎖、取消請求、讀檔錯誤的文字鍵與資料不變性。 |

## 4. 現階段不通過項目

目前不可宣稱完整一輪通過，原因如下：

1. 各服務已有多支單元／局部整合測試，但尚無一份將 `MissionRunRecord`、固定結果、`ClaimReceipt`、地盤觸及與人物寫回串起來的可保存整合流程。
2. 桌面主畫面現階段仍以任務 ID、時長與是否接受為主，尚未接入文字暫代規格中的派遣、倒數、收取、錯誤與長期成長操作。
3. 新手完成流程目前的到期／釋放／推進順序尚未接至新規則：完成時釋放人物，收取時才套用成果與教學推進；取消服務不得成為第一版玩家操作。
4. 刷新額度、地盤成長、收藏、布置與人物解鎖尚未共同存入 `PlayerSaveEnvelope`，因此無法證明重啟後的整體不變性。
5. 教學的中斷復原與本機匿名行為日誌已有主規格要求，但尚未列入此次完整一輪整合證據組。

## 5. 後續不需核准的可行性審核

下一個安全審核應確認「完成時安全釋放人物」與「收取時才提交成果效果」之間的接線風險；它只產出差異與保留／退役界線，不修改程式或既有主規格。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 日期時間 | 2026-08-10 Asia/Taipei |
| 類型 | 設計補充／完整一輪遊玩驗收矩陣 |
| 目標 | 將八項已核准循環要求映射到資料服務、文字 UI、可視化操作、headless／手動證據與缺少接線。 |
| 檔案相對位置 | `docs/superpowers/specs/2026-08-10-bgi-desktop-full-loop-acceptance-matrix.md` |
| 行號 | 1–90；驗收矩陣 15–25、證據格式 27–50、現階段不通過項目 52–60、後續審核範圍 62–64。 |
| 變更摘要 | 新增八列驗收矩陣、證據格式、目前不通過項目與下一個可行性審核範圍。 |
| 驗證結果 | 已對照主規格、full-loop contract supplement、文字暫代 UI 規格、既有測試名稱與 Godot 測試操作文件；未改主規格、Godot 或素材。 |
| 預期 Git commit | 待日誌分支提交 |
