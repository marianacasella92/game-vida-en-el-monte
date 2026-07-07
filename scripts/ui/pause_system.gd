extends Node3D

## Menú de pausa: alterna con `ui_cancel` (Escape) cuando no hay otra
## pantalla modal abierta. Registrado en UIState como &"pause".
##
## Todo el manejo de ui_cancel vive acá en _process, no en _unhandled_input:
## si abrir y cerrar reaccionaran los dos al mismo evento (mismo Escape),
## _unhandled_input abriría el menú y en ese mismo frame el chequeo de cierre
## lo volvería a cerrar (is_action_just_pressed sigue "true" todo el frame).
##
## Además de las pantallas modales (UIState), Escape tampoco abre pausa con
## una pieza de construcción equipada — eso es estado de gameplay (no una
## pantalla), y ese mismo Escape ya lo usa build_system para sacar la pieza
## de la mano. Por eso se consulta build_system directo, aparte de UIState.

const MODAL_ID := &"pause"

@onready var panel: Control = $PauseUILayer/Panel

func _ready() -> void:
	add_to_group("pause_system")
	panel.visible = false

func open_pause() -> void:
	UIState.open(MODAL_ID)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.visible = true

func close_pause() -> void:
	UIState.close(MODAL_ID)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	panel.visible = false

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("ui_cancel"):
		return
	if UIState.is_open(MODAL_ID):
		close_pause()
		return
	if UIState.is_any_modal_open():
		return
	var build_system := get_tree().get_first_node_in_group("build_system")
	if build_system and build_system.equipped_category != "none":
		return
	open_pause()
