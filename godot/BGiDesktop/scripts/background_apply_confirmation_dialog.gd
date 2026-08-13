class_name BackgroundApplyConfirmationDialog
extends Control

signal apply_requested
signal defer_requested

@onready var confirm_button: Button = %ConfirmApplyButton
@onready var defer_button: Button = %DeferApplyButton

func _ready() -> void:
	confirm_button.pressed.connect(_on_confirm_pressed)
	defer_button.pressed.connect(_on_defer_pressed)
	hide()

## Shows only the visual confirmation shell; background ownership and replacement remain external.
func present() -> void:
	show()
	confirm_button.grab_focus()

func _on_confirm_pressed() -> void:
	hide()
	apply_requested.emit()

func _on_defer_pressed() -> void:
	hide()
	defer_requested.emit()
