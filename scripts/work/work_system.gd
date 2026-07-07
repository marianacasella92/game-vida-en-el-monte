extends Node3D

## Estado "trabajando": al sentarse en un escritorio, bloquea el movimiento
## normal del jugador, mueve la cámara a la posición fija del escritorio
## (nodo "SitSpot" de la pieza) y muestra el mini-juego de "dar clase en
## vivo" (attention_minigame.gd) encima.

## Registrado en UIState como &"work" mientras dura la sesión. `is_working`
## se mantiene como estado propio porque no es solo "pantalla abierta":
## PlayerNeeds lo consulta para el desgaste de sueño por esfuerzo
## (_is_exerting), que es gameplay, no UI.
const MODAL_ID := &"work"

var is_working: bool = false

@onready var player: CharacterBody3D = get_parent()
@onready var head: Node3D = get_node("../Head")
@onready var work_panel: Control = $WorkUILayer/Panel
@onready var minigame: Control = $WorkUILayer/Panel/AttentionMinigame

var _saved_transform: Transform3D
var _saved_head_pitch: float = 0.0

func _ready() -> void:
	add_to_group("work_system")
	work_panel.visible = false
	minigame.session_ended.connect(_on_session_ended)

func start_working(desk: Node3D) -> void:
	if is_working:
		return

	_saved_transform = player.global_transform
	_saved_head_pitch = head.rotation.x

	var sit_spot: Node3D = desk.get_node("SitSpot")
	player.global_transform = sit_spot.global_transform
	head.rotation.x = 0.0

	is_working = true
	UIState.open(MODAL_ID)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	work_panel.visible = true
	minigame.start_session()

func stop_working() -> void:
	if not is_working:
		return

	is_working = false
	UIState.close(MODAL_ID)
	player.global_transform = _saved_transform
	head.rotation.x = _saved_head_pitch
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	work_panel.visible = false
	minigame.reset()

func _on_session_ended(_average: float, money_awarded: int) -> void:
	Economy.add_money(money_awarded)

## "close_window" (Q) — ver el comentario en phone_system.gd sobre por qué
## está separada de "ui_cancel" (Esc, exclusiva del menú de pausa).
func _process(_delta: float) -> void:
	if is_working and Input.is_action_just_pressed("close_window"):
		stop_working()
