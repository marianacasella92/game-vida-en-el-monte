extends Node3D

## Pantalla de mochila (PXD_Diseno_HUD_UI_v1.md, sección 4): se abre/cierra
## con `open_inventory` desde cualquier punto del mundo. Registrada en
## UIState como &"inventory" — el bloqueo de mouse-look/movimiento/otras
## pantallas sale de ahí.

const MODAL_ID := &"inventory"

@onready var panel: Control = $InventoryUILayer/Panel

func _ready() -> void:
	add_to_group("inventory_system")
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("open_inventory"):
		return
	if UIState.is_any_modal_open_except(MODAL_ID):
		return
	if UIState.is_open(MODAL_ID):
		close_inventory()
	else:
		open_inventory()

func open_inventory() -> void:
	UIState.open(MODAL_ID)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.visible = true
	panel.refresh()

func close_inventory() -> void:
	UIState.close(MODAL_ID)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	panel.visible = false

## "close_window" (Q) — ver el comentario en phone_system.gd sobre por qué
## está separada de "ui_cancel" (Esc, exclusiva del menú de pausa).
func _process(_delta: float) -> void:
	if UIState.is_open(MODAL_ID) and Input.is_action_just_pressed("close_window"):
		close_inventory()
