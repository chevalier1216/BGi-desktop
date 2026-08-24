# BGi Desktop：任務生命週期狀態所有權與轉換表

> 日期：2026-08-10（Asia/Taipei）
> 狀態：可交給 lifecycle coordinator 接線的獨立規格。
> 依據：完整一輪資料契約、文字暫代 UI 規格、任務釋放與收取可行性審核。
> 非範圍：不修改主規格、Godot 或素材；不設定報酬、機率、地盤效果與任何數值，未定內容維持 `[PLACEHOLDER]`。

## 1. 核心原則

- `mission_run_id` 是一次派遣的唯一識別；`mission_template_id`／既有 `task_id` 只描述任務模板。任何結果、收據、釋放或復原不得只以模板 ID 判定唯一性。
- `MissionRunRecord` 是任務生命週期的權威資料；`ClaimReceipt` 是效果已套用的權威資料；`crew_by_id` 是人物可用／派遣中狀態的權威資料。
- UI、時計、任務卡與背景提示僅顯示衍生狀態，不能改寫權威資料。
- 每個轉換以「先保存下一筆權威資料，再改 UI」為原則。任務完成時，結果快照、`completed_pending_claim` 與人物恢復可用必須一同安全保存；保存失敗時停留在前一個已保存狀態，不釋放人物、不推進教學、不增加地盤效果。
- 第一版不提供玩家取消任務。`MissionAbortService` 只能作為內部測試／修復能力，不得由 UI 或快捷鍵觸發。

## 2. 狀態與唯一權威資料

| 狀態 | 對玩家的意義 | 任務權威資料 | 人物權威資料 | UI 唯讀依據 | 唯一可發動者 |
| --- | --- | --- | --- | --- | --- |
| `available` | 可接受任務。 | `MissionBoardEntry.board_state=available`；無 `active_mission_run_id`。 | 人物可用或忙碌由 `crew_by_id` 個別狀態決定。 | 任務卡、派遣選擇。 | 玩家確認派遣，交由 lifecycle coordinator。 |
| `accepting` | 內部交易中，尚未對玩家宣告成功。 | 尚未保存的新 `MissionRunRecord` 草稿。 | 尚未保存的人物派遣中草稿。 | 僅顯示處理中，不改任務卡主狀態。 | lifecycle coordinator。 |
| `active` | 已派遣、正在等待完成。 | 已保存的 `MissionRunRecord`：隊伍、倍率、開始／到期時間、`run_state=active`。 | `assigned_crew_ids` 對應人物皆為派遣中。 | 派遣中卡、倒數、隊伍名單。 | lifecycle coordinator 接受成功後。 |
| `result_locked` | 已到期，結果已固定但結果／狀態保存尚在交易中。 | 已產生但尚未完成保存的 `result_snapshot` 草稿。 | 人物維持派遣中。 | 僅顯示處理中，不提前顯示收取。 | lifecycle coordinator。 |
| `completed_pending_claim` | 結果已安全固定，可由玩家收取。 | 已保存 `MissionRunRecord.result_snapshot`，`run_state=completed_pending_claim`，無 `claim_receipt_id`。 | 原派遣人物已保存為可用，可參與其他任務。 | 可收取卡與固定結果；人物區不得將其標為忙碌。 | lifecycle coordinator 完成結果與人物可用狀態保存後。 |
| `claim_committing` | 玩家已點收取，正在保存收據與效果。 | `ClaimReceipt` 草稿與預計效果草稿。 | 人物維持可用；本交易不再次變更人物可用性。 | 僅顯示收取處理中；保留可收取結果畫面。 | lifecycle coordinator。 |
| `claimed` | 結果已收取且效果已完成一次。 | 已保存 `ClaimReceipt`、`claim_receipt_id`、`run_state=claimed`。 | 人物維持可用。 | 已收取卡、收據與長期成長結果。 | lifecycle coordinator 完成收據、效果與存檔後。 |
| `recovery_hold` | 任務資料不足以安全繼續。 | 已保存 `run_state=recovery_hold`、`recovery_reason`；不建立或修改結果／收據。 | 只保留可驗證的既有狀態；不可猜測釋放。 | 安全復原訊息與錯誤碼。 | 存檔復原程序。 |

人物釋放不是可獨立跳轉的任務終態；它是 `active → completed_pending_claim` 的完成交易內部步驟。人物可用不代表成果已收取；任務仍永久保留在 `completed_pending_claim` 或 `claimed`，直到玩家收取固定結果。

## 3. 唯一允許轉換

| 起點 | 事件／前置 | 原子保存順序 | 終點 | 必須同時成立 |
| --- | --- | --- | --- | --- |
| `available` | 人數、人物可用性與全域並行限制檢核通過。 | 保存 `MissionRunRecord` 與人物派遣狀態；若任一失敗，回滾全部草稿。 | `active` | 一筆新的 `mission_run_id`、有效隊伍、開始／到期時間。 |
| `active` | `now_seconds >= due_at_seconds`，時計與隊伍仍可驗證。 | 建立／讀回固定結果；保存 `result_snapshot`、`run_state=completed_pending_claim` 與原派遣人物恢復可用狀態。 | `completed_pending_claim` | 首次固定後，重啟或重試均回傳同一 `result_id`；人物可再派遣，但成果未入帳。 |
| `completed_pending_claim` | 玩家按收取，尚無 `ClaimReceipt`。 | 保存唯一 `ClaimReceipt` → 套用已識別效果 → 保存地盤／人物解鎖／教學變化 → 保存 `run_state=claimed`。 | `claimed` | 同一 `mission_run_id` 最多一張收據；人物在此交易前已可用，且不重複套用效果。 |
| `completed_pending_claim` | 玩家重複按收取，已有 `ClaimReceipt`。 | 不新增任何資料；讀回既有收據。 | `claimed` | 無重複效果、無結果改寫；不改變人物現有派遣狀態。 |
| `active` 或 `completed_pending_claim` | 讀檔時缺少必要 ID、隊伍、時間或結果關聯。 | 保存 `recovery_reason`；不得建立結果、收據或效果。 | `recovery_hold` | UI 不可提供收取、刷新替換或取消。 |
| `recovery_hold` | 已可識別原 run、隊伍、時計與既有結果狀態。 | 保存修復後完整 `MissionRunRecord`。 | `active` 或 `completed_pending_claim` | 只回到可由已保存資料證明的狀態。 |

## 4. 禁止轉換與原因

| 禁止轉換 | 禁止原因 | 必須回應 |
| --- | --- | --- |
| `active → claimed` | 跳過結果固定、收據與玩家收取。 | 保持 `active` 或完成後進入 `completed_pending_claim`。 |
| `active → available` | 等同玩家取消或提前釋放。 | `mission_cancel_not_supported`，資料不變。 |
| `completed_pending_claim → available`（任務狀態） | 會遺失固定結果或讓同一模板重派。 | 拒絕，保留可收取結果；但人物可用狀態已在完成交易中獨立恢復。 |
| `completed_pending_claim → active` | 結果已固定，不能回到倒數或重骰。 | 拒絕，保留固定結果。 |
| `claimed → active`、`claimed → completed_pending_claim` | 已收據化的效果不得逆轉或重複套用。 | 讀回既有收據。 |
| `active` 以外任意狀態 → 人物釋放 | 會使人物狀態與可驗證的完成時間脫節。 | 只有 lifecycle coordinator 在安全完成交易中可釋放原派遣人物。 |
| `recovery_hold → claimed` | 讀檔資料不足時不能補發結果或效果。 | 維持安全復原，等待可驗證資料。 |
| 結果快照已存在後重新解析為新結果 | 會改寫已知結果或重骰額外報酬。 | 回傳既有 `result_snapshot`。 |

## 5. lifecycle coordinator 對照與接線限制

現有 `mission_lifecycle_coordinator.gd` 的「收取時再釋放」時序已被產品規則取代：接受時建立時計，到期時先鎖定結果並安全釋放人物，收取時再提交成果效果。下列限制必須在完整一輪接線前處理。

| 目前行為 | 可保留部分 | 需要改為的權威資料邊界 |
| --- | --- | --- |
| 以 `task_id` 作為快照、結果與已收取集合鍵。 | 既有時計與結果鎖定流程。 | 改用 `mission_run_id`；同一模板在日後可有多次執行，不可共用結果／收據。 |
| `_locked_results_by_task_id` 與 `_claimed_task_ids` 僅在 coordinator 記憶體。 | 記憶體快取可作加速。 | 權威資料必須進入 `MissionRunRecord.result_snapshot` 與 `ClaimReceipt`，重啟後可重建。 |
| `claim_completed_result()` 先取得 claim service 結果、再釋放人物、最後才寫入已收取集合。 | 收取後提交成果的時序。 | 將人物釋放移至完成交易；收取交易只保存收據、效果、長期進度與已領取狀態。 |
| 透過 `MissionExpiredReleaseService` 釋放人物。 | 到期與有效性檢核。 | 僅允許由成功完成交易呼叫；不可作為玩家取消入口，也不得在收取交易中再次釋放。 |
| 收取後移除時計快照。 | 已收取後不再需要活動倒數。 | 結果、`completed_pending_claim` 與人物釋放保存成功後即可移除活動時計；收據與 `run_state=claimed` 仍須於收取成功後保存。 |

## 6. 存檔復原表

| 載入時發現 | 可恢復狀態 | UI | 禁止行為 |
| --- | --- | --- | --- |
| 有完整活動任務與時計，尚未到期。 | `active`。 | 顯示原倒數與派遣人物。 | 重派、取消、刷新替換。 |
| 有完整活動任務，載入時已到期，尚無固定結果。 | 先執行 `active → completed_pending_claim` 的固定結果與人物釋放保存。 | 保存成功後顯示可收取，原派遣人物可用。 | 未保存前顯示收取或釋放人物。 |
| 有固定結果，尚無收據。 | `completed_pending_claim`。 | 顯示同一固定結果與收取按鈕；人物顯示可用，任務卡顯示待收取。 | 重骰、重派同一任務或自動收取。 |
| 有收據與已領取狀態。 | `claimed`。 | 顯示收據／歷史。 | 再次套用效果或再次釋放。 |
| 缺少必要資料、資料互相矛盾或版本不支援。 | `recovery_hold` 或整體唯讀讀檔錯誤頁。 | 顯示錯誤碼、重試讀取。 | 覆寫原檔、自動補發成果、猜測人物狀態。 |

## 7. 最小邊界驗收

1. 同一 `mission_run_id` 在到期後連續解析兩次，產生或回傳完全相同的 `result_id`；完成保存成功後，任務為待收取，原派遣人物可再派遣。
2. 同一 `mission_run_id` 連續收取兩次，只有第一次建立收據並套用效果；第二次只讀回同一收據，不改變人物現有派遣狀態。
3. 完成保存失敗時，任務維持 `active` 且人物維持派遣中；收取保存失敗時，任務停在 `completed_pending_claim`、人物維持可用，教學與地盤資料不變。
4. 以相同 `mission_template_id` 建立兩次不同 `mission_run_id`，兩筆結果與收據不能互相覆寫。
5. 對 `active` 任務發出取消請求，回傳 `mission_cancel_not_supported`；任務、隊伍、時計與結果資料不變。
6. 缺少任一必要復原欄位時，不產生報酬或收據，僅進入 `recovery_hold` 或唯讀讀檔錯誤頁。

## OPLOG_HANDOFF

| 欄位 | 內容 |
| --- | --- |
| 日期時間 | 2026-08-10 Asia/Taipei |
| 類型 | 設計補充／任務生命週期狀態所有權與轉換 |
| 目標 | 定義接受、派遣中、結果固定、待領取、已領取、人物釋放與存檔復原的唯一權威資料及禁止轉換。 |
| 檔案相對位置 | `docs/superpowers/specs/2026-08-10-bgi-desktop-mission-lifecycle-state-ownership.md` |
| 行號 | 1–97；核心原則 9–15、狀態所有權 17–31、允許／禁止轉換 33–52、coordinator 接線 54–65、復原與驗收 67–84。 |
| 變更摘要 | 新增狀態所有權、唯一允許／禁止轉換、lifecycle coordinator 接線限制、存檔復原表與邊界驗收。 |
| 驗證結果 | 已對照完整一輪契約、文字 UI、釋放可行性審核與現有 lifecycle coordinator；未改主規格、Godot 或素材。 |
| 預期 Git commit | 待日誌分支提交 |
