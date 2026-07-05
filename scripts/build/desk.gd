extends StaticBody3D

## Detección de proximidad del escritorio: muestra "Presioná E" cuando la
## jugadora entra al área, lo oculta al salir. Todavía no reacciona a la
## tecla `interact` — eso se suma en el próximo ítem (estado "trabajando").

@export var interaction_range: float = 2.5

@onready var area: Area3D = $InteractionArea
@onready var area_shape: CollisionShape3D = $InteractionArea/CollisionShape3D
@onready var prompt: Label3D = $InteractPrompt

func _ready() -> void:
	var shape := SphereShape3D.new()
	shape.radius = interaction_range
	area_shape.shape = shape
	area.body_entered.connect(_on_body_entered)
	area.body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		prompt.visible = true

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		prompt.visible = false
