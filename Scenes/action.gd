class_name ActionRow
extends HBoxContainer

# Export specific nodes so you can assign them in the Inspector
# (or keep strict naming if you prefer, but this is safer)
@onready var button: Button = $ColorRect/Button
@onready var _cost_label: Label = $ColorRect2/Label

var required_pp: int = 0
var _callback: Callable


func setup(text: String, cost: int, on_click: Callable) -> void:
	required_pp = cost
	_callback = on_click
	if is_inside_tree():
		if button:
			button.text = text
		if _cost_label:
			_cost_label.text = str(cost)


func _ready() -> void:
	if button:
		button.pressed.connect(_on_button_pressed)


func _on_button_pressed() -> void:
	if _callback.is_valid():
		_callback.call()
