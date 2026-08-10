extends Control

@onready var topmost_toggle: CheckButton = %TopmostToggle
@onready var layout_button: Button = %LayoutButton

func _ready() -> void:
	topmost_toggle.button_pressed = DesktopWindowController.is_always_on_top()
	topmost_toggle.toggled.connect(DesktopWindowController.set_always_on_top)
	layout_button.pressed.connect(DesktopWindowController.toggle_layout_density)

