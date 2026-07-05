extends Node3D

## Estado "trabajando": al sentarse en un escritorio, bloquea el movimiento
## normal del jugador, mueve la cámara a la posición fija del escritorio
## (nodo "SitSpot" de la pieza) y muestra una UI simple encima. Todavía no
## hay mini-juego real (próximo ítem de Milestone 2) — por ahora la UI es
## un placeholder y la única salida es Escape.

var is_working: bool = false

@onready var player: CharacterBody3D = get_parent()
@onready var head: Node3D = get_node("../Head")
@onready var work_panel: Control = $WorkUILayer/Panel

var _saved_transform: Transform3D
var _saved_head_pitch: float = 0.0

func _ready() -> void:
	add_to_group("work_system")
	work_panel.visible = false

func start_working(desk: Node3D) -> void:
	if is_working:
		return

	_saved_transform = player.global_transform
	_saved_head_pitch = head.rotation.x

	var sit_spot: Node3D = desk.get_node("SitSpot")
	player.global_transform = sit_spot.global_transform
	head.rotation.x = 0.0

	is_working = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	work_panel.visible = true

func stop_working() -> void:
	if not is_working:
		return

	is_working = false
	player.global_transform = _saved_transform
	head.rotation.x = _saved_head_pitch
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	work_panel.visible = false

## Se revisa en _process (no en _unhandled_input) para que este cierre de
## sesión se procese siempre después del manejo genérico de "ui_cancel" que
## hace player.gd (el input se despacha antes que _process en cada frame),
## y así la recaptura del mouse al salir no quede pisada por ese handler.
func _process(_delta: float) -> void:
	if is_working and Input.is_action_just_pressed("ui_cancel"):
		stop_working()
