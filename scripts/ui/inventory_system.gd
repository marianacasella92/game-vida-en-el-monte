extends Node3D

## Pantalla de mochila (PXD_Diseno_HUD_UI_v1.md, sección 4): se abre/cierra
## con `open_inventory` desde cualquier punto del mundo, sin necesidad de
## acercarse a nada. Mismo patrón que phone_system.gd — bloquea mouse-look
## y movimiento mientras está abierta (ver player.gd, que revisa
## inventory_system.is_open).

var is_open: bool = false

@onready var work_system: Node = get_node("../WorkSystem")
@onready var build_system: Node = get_node("../BuildSystem")
@onready var phone_system: Node = get_node("../PhoneSystem")
@onready var panel: Control = $InventoryUILayer/Panel

func _ready() -> void:
	add_to_group("inventory_system")
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("open_inventory"):
		return
	if work_system.is_working or build_system.menu_open or phone_system.is_open:
		return
	if is_open:
		close_inventory()
	else:
		open_inventory()

func open_inventory() -> void:
	is_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.visible = true
	panel.refresh()

func close_inventory() -> void:
	is_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	panel.visible = false

## Se revisa en _process (no en _unhandled_input) por la misma razón que
## documenta phone_system.gd: así la recaptura del mouse al salir no queda
## pisada por el handler genérico de "ui_cancel" de player.gd.
func _process(_delta: float) -> void:
	if is_open and Input.is_action_just_pressed("ui_cancel"):
		close_inventory()
