extends Node3D

## Celular que la jugadora siempre lleva encima (GDD 4.10): se abre/cierra con
## `open_phone` desde cualquier punto del mundo, sin necesidad de acercarse a
## nada. Bloquea mouse-look/movimiento igual que WorkSystem mientras está abierto.

var is_open: bool = false

@onready var work_system: Node = get_node("../WorkSystem")
@onready var build_system: Node = get_node("../BuildSystem")
@onready var inventory_system: Node = get_node("../InventorySystem")
@onready var pause_system: Node = get_node("../PauseSystem")
@onready var panel: Control = $PhoneUILayer/Panel

func _ready() -> void:
	add_to_group("phone_system")
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("open_phone"):
		return
	if work_system.is_working or build_system.menu_open or inventory_system.is_open or pause_system.is_open:
		return
	if is_open:
		close_phone()
	else:
		open_phone()

func open_phone() -> void:
	is_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.visible = true
	panel.refresh()

func close_phone() -> void:
	is_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	panel.visible = false

## "close_window" (Q) es la tecla dedicada para cerrar cualquier pantalla
## modal — separada de "ui_cancel" (Esc), que ahora es exclusiva del menú de
## pausa (pause_system.gd), para que abrir/cerrar una pantalla y abrir pausa
## nunca compitan por el mismo evento en el mismo frame.
func _process(_delta: float) -> void:
	if is_open and Input.is_action_just_pressed("close_window"):
		close_phone()
