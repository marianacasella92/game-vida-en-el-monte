extends StaticBody3D

## Base reusable para piezas que muestran un prompt de interacción por
## proximidad (cama, escritorio, y cualquier mueble futuro con el mismo
## patrón): Area3D + InteractPrompt + guardas de pantallas modales, todo en
## un solo lugar. Antes cada pieza copiaba este mismo bloque a mano
## (bed.gd/desk.gd eran casi idénticos) — una pieza nueva solo necesita
## heredar este script (extends "res://scripts/build/proximity_interactable.gd")
## y sobreescribir _on_interact() con lo que hace su acción particular.
##
## Requiere en la escena: un Area3D "InteractionArea" (con su
## CollisionShape3D, el shape se arma acá con `interaction_range`) y una
## instancia de interaction_prompt_3d.tscn llamada "InteractPrompt", ambos
## hijos directos del nodo raíz — mismo layout que ya tenían bed.tscn/desk.tscn.

@export var interaction_range: float = 2.0
@export var action_text: String = "Interactuar"

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
		prompt.show_prompt(action_text)

func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player = null
		prompt.hide_prompt()

func _unhandled_input(event: InputEvent) -> void:
	if not (_player and event.is_action_pressed("interact")):
		return
	if _any_modal_open():
		return
	_on_interact()

func _any_modal_open() -> bool:
	var phone_system := get_tree().get_first_node_in_group("phone_system")
	if phone_system and phone_system.is_open:
		return true
	var inventory_system := get_tree().get_first_node_in_group("inventory_system")
	if inventory_system and inventory_system.is_open:
		return true
	var pause_system := get_tree().get_first_node_in_group("pause_system")
	if pause_system and pause_system.is_open:
		return true
	return false

## Cada pieza concreta sobreescribe esto con su propia acción (dormir,
## empezar a trabajar, etc.) — lo único que le hace falta escribir.
func _on_interact() -> void:
	pass
