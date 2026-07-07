extends Node3D

## Prompt de interacción reusable (PXD_Diseno_HUD_UI_v1.md, sección 3):
## ícono de tecla (imagen real del keyset, no texto compuesto a mano sobre un
## marco dibujado) + texto de acción, billboardeado en el mundo 3D sobre el
## objeto interactuable. La tecla se lee de InputMap en vez de hardcodear
## "E", para que se actualice sola si se remapea el control.

const KEYSET_DIR := "res://assets/hud/keyset/White/"

## OS.get_keycode_string() -> nombre de archivo del keyset, solo para las
## teclas cuyo nombre no coincide directo con el archivo. Letras, números y
## F1-F12 no necesitan entrada acá: "E" ya es "E.png", "1" ya es "1.png".
const SPECIAL_KEY_ICONS := {
	"Escape": "esc",
	"Space": "space_bar",
	"Enter": "enter",
	"Kp Enter": "enter",
	"Tab": "tab",
	"Backspace": "backspace",
	"Shift": "shift",
	"Ctrl": "ctrl",
	"Alt": "alt",
	"Delete": "del",
	"Home": "home",
	"End": "end",
	"Page Up": "pgup",
	"Page Down": "pgdn",
	"Up": "up_arrow",
	"Down": "down_arrow",
	"Left": "left_arrow",
	"Right": "right_arrow",
	"Caps Lock": "capslock",
}

@onready var key_sprite: Sprite3D = $KeySprite
@onready var action_label: Label3D = $ActionLabel

func _ready() -> void:
	visible = false
	_update_key_icon()

## `key_icon` (opcional): nombre de archivo del keyset a mostrar directo (sin
## el ".png"), para acciones que no son la tecla "interact" — ej. "left_mouse"
## para sembrar/regar (click izquierdo), que no tiene una acción con nombre en
## InputMap para resolver sola. Si se omite, se sigue leyendo de "interact"
## (comportamiento de siempre, usado por cama/escritorio/cosechar).
func show_prompt(action_text: String, key_icon: String = "") -> void:
	action_label.text = action_text
	if key_icon != "":
		_set_key_icon(key_icon)
	else:
		_update_key_icon()
	visible = true

func hide_prompt() -> void:
	visible = false

func _update_key_icon() -> void:
	for event in InputMap.action_get_events("interact"):
		if event is InputEventKey:
			var raw: String = OS.get_keycode_string(event.physical_keycode)
			var file_name: String = SPECIAL_KEY_ICONS.get(raw, raw)
			_set_key_icon(file_name)
			return

func _set_key_icon(file_name: String) -> void:
	var path: String = "%s%s.png" % [KEYSET_DIR, file_name]
	if ResourceLoader.exists(path):
		key_sprite.texture = load(path)
