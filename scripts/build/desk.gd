extends StaticBody3D

## Detección de proximidad del escritorio: muestra "Presioná E" cuando la
## jugadora entra al área, lo oculta al salir. Al presionar `interact`
## estando en rango, le avisa al WorkSystem del jugador para que entre al
## estado "trabajando" (ver scripts/work/work_system.gd).

@export var interaction_range: float = 2.5

@onready var area: Area3D = $InteractionArea
@onready var area_shape: CollisionShape3D = $InteractionArea/CollisionShape3D
@onready var prompt: Node3D = $InteractPrompt

var _player: Node3D = null

func _ready() -> void:
	var shape := SphereShape3D.new()
	shape.radius = interaction_range
	area_shape.shape = shape
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	prompt.hide_prompt()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = body
		prompt.show_prompt("Trabajar")

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = null
		prompt.hide_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if _player and event.is_action_pressed("interact"):
		var phone_system := get_tree().get_first_node_in_group("phone_system")
		if phone_system and phone_system.is_open:
			return
		var inventory_system := get_tree().get_first_node_in_group("inventory_system")
		if inventory_system and inventory_system.is_open:
			return
		var pause_system := get_tree().get_first_node_in_group("pause_system")
		if pause_system and pause_system.is_open:
			return
		var work_system := get_tree().get_first_node_in_group("work_system")
		if work_system:
			work_system.start_working(self)
