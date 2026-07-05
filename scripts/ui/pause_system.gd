extends Node3D

## Menú de pausa: alterna con `ui_cancel` (Escape) cuando no hay otra pantalla
## modal abierta. Mismo nivel que PhoneSystem/InventorySystem/BuildSystem/
## WorkSystem, a los que bloquea mientras está abierto.
##
## Todo el manejo de ui_cancel vive acá en _process, no en _unhandled_input:
## si abrir y cerrar reaccionaran los dos al mismo evento (mismo Escape),
## _unhandled_input abriría el menú y en ese mismo frame el chequeo de cierre
## lo volvería a cerrar (is_action_just_pressed sigue "true" todo el frame).
## Al vivir los dos lados del toggle en un único _process, se evalúan una
## sola vez por frame — y de paso, corre después del handler genérico de
## ui_cancel de player.gd (que fuerza el mouse a visible sin condición), así
## que la recaptura del mouse al cerrar no queda pisada.
##
## Se chequea build_system.is_active() (no solo menu_open): construcción ya
## manejaba ui_cancel por su cuenta para sacar una pieza equipada de la mano
## con el catálogo cerrado — sin este chequeo, ese mismo Escape también
## abriría el menú de pausa encima.

var is_open: bool = false

@onready var work_system: Node = get_node("../WorkSystem")
@onready var build_system: Node = get_node("../BuildSystem")
@onready var phone_system: Node = get_node("../PhoneSystem")
@onready var inventory_system: Node = get_node("../InventorySystem")
@onready var panel: Control = $PauseUILayer/Panel

func _ready() -> void:
	add_to_group("pause_system")
	panel.visible = false

func open_pause() -> void:
	is_open = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.visible = true

func close_pause() -> void:
	is_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	panel.visible = false

func _process(_delta: float) -> void:
	if not Input.is_action_just_pressed("ui_cancel"):
		return
	if is_open:
		close_pause()
		return
	if work_system.is_working or build_system.is_active() or phone_system.is_open or inventory_system.is_open:
		return
	open_pause()
