extends StaticBody3D

## Detección de proximidad de la cama, mismo patrón que desk.gd: muestra
## "Presioná E para dormir" al entrar al área. Al presionar `interact` en
## rango, restaura el sueño al máximo de una — sin transición de día/noche
## todavía (eso es Sprint 4.4), ni animación de dormir.

@export var interaction_range: float = 2.0

@onready var area: Area3D = $InteractionArea
@onready var area_shape: CollisionShape3D = $InteractionArea/CollisionShape3D
@onready var prompt: Label3D = $InteractPrompt

var _player: Node3D = null

func _ready() -> void:
	var shape := SphereShape3D.new()
	shape.radius = interaction_range
	area_shape.shape = shape
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)
	prompt.visible = false

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = body
		prompt.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = null
		prompt.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if _player and event.is_action_pressed("interact"):
		var phone_system := get_tree().get_first_node_in_group("phone_system")
		if phone_system and phone_system.is_open:
			return
		PlayerNeeds.sleep_now()
		print("[needs] durmió, sueño=%.0f" % PlayerNeeds.sleep)
