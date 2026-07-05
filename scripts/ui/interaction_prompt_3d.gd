extends Node3D

## Prompt de interacción reusable (PXD_Diseno_HUD_UI_v1.md, sección 3):
## marco + tecla dinámica + texto de acción, billboardeado en el mundo 3D
## sobre el objeto interactuable. La tecla se lee de InputMap en vez de
## hardcodear "E", para que se actualice sola si se remapea el control.

@onready var key_label: Label3D = $Frame/KeyLabel
@onready var action_label: Label3D = $ActionLabel

func _ready() -> void:
	visible = false
	key_label.text = _current_interact_key_label()

func show_prompt(action_text: String) -> void:
	action_label.text = action_text
	key_label.text = _current_interact_key_label()
	visible = true

func hide_prompt() -> void:
	visible = false

func _current_interact_key_label() -> String:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			return OS.get_keycode_string(event.physical_keycode)
	return "?"
