class_name MissionLifecyclePanel
extends PanelContainer

signal accept_requested
signal completion_check_requested
signal claim_requested

const STATE_AVAILABLE: String = "available"
const STATE_DISPATCHED: String = "dispatched"
const STATE_COMPLETED: String = "completed"
const STATE_CLAIMED: String = "claimed"

@onready var task_label: Label = %TaskLabel
@onready var state_label: Label = %StateLabel
@onready var detail_label: Label = %DetailLabel
@onready var accept_button: Button = %AcceptButton
@onready var completion_button: Button = %CompletionButton
@onready var claim_button: Button = %ClaimButton

func _ready() -> void:
	accept_button.pressed.connect(_on_accept_pressed)
	completion_button.pressed.connect(_on_completion_pressed)
	claim_button.pressed.connect(_on_claim_pressed)
	set_task_state("starter_01", STATE_AVAILABLE)

## Renders one local test task without making gameplay decisions.
func set_task_state(task_id: String, state: String, detail: String = "") -> void:
	task_label.text = "測試任務：%s" % task_id
	detail_label.text = detail
	accept_button.disabled = state != STATE_AVAILABLE
	completion_button.disabled = state != STATE_DISPATCHED
	claim_button.disabled = state != STATE_COMPLETED
	match state:
		STATE_AVAILABLE:
			state_label.text = "狀態：任務接受（可派遣）"
		STATE_DISPATCHED:
			state_label.text = "狀態：派遣中"
		STATE_COMPLETED:
			state_label.text = "狀態：完成待收取"
		STATE_CLAIMED:
			state_label.text = "狀態：已收取"
		_:
			state_label.text = "狀態：未知"
			accept_button.disabled = true
			completion_button.disabled = true
			claim_button.disabled = true

func _on_accept_pressed() -> void:
	accept_requested.emit()

func _on_completion_pressed() -> void:
	completion_check_requested.emit()

func _on_claim_pressed() -> void:
	claim_requested.emit()
