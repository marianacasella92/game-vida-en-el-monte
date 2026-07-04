extends Node3D

@export var build_range: float = 5.0
@export var grid_size: float = 1.0

const PIECE_SCENES := {
	"wall": preload("res://scenes/build/wall.tscn"),
	"floor": preload("res://scenes/build/floor.tscn"),
	"roof": preload("res://scenes/build/roof.tscn"),
}

@onready var camera: Camera3D = get_node("../Head/Camera3D")
@onready var player: CharacterBody3D = get_parent()
@onready var radial_menu: Control = $RadialMenuLayer/Wheel

var equipped_piece: String = "none"
var ghost: StaticBody3D
var ghost_mesh: MeshInstance3D
var ghost_shape: Shape3D
var ghost_valid: bool = false
var menu_open: bool = false

var valid_material := StandardMaterial3D.new()
var invalid_material := StandardMaterial3D.new()

func _ready() -> void:
	valid_material.albedo_color = Color(0.2, 1.0, 0.2, 0.5)
	valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	valid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	invalid_material.albedo_color = Color(1.0, 0.2, 0.2, 0.5)
	invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	invalid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	_spawn_ghost()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		menu_open = true
		if ghost:
			ghost.visible = false
		radial_menu.open()
	elif event.is_action_released("build_menu"):
		menu_open = false
		var choice: String = radial_menu.close()
		if choice != "":
			equipped_piece = choice
			_spawn_ghost()
		elif ghost:
			ghost.visible = true
	elif menu_open and event is InputEventMouseMotion:
		radial_menu.add_motion(event.relative)
	elif event is InputEventMouseButton and event.pressed and not menu_open:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_piece()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_remove_piece()

func _spawn_ghost() -> void:
	if ghost:
		ghost.queue_free()
		ghost = null
		ghost_mesh = null
		ghost_shape = null

	if equipped_piece == "none":
		return

	ghost = PIECE_SCENES[equipped_piece].instantiate()
	add_child(ghost)

	ghost_mesh = ghost.get_node("MeshInstance3D")
	var collision: CollisionShape3D = ghost.get_node("CollisionShape3D")
	ghost_shape = collision.shape
	collision.disabled = true
	ghost.collision_layer = 0
	ghost.collision_mask = 0

func _place_piece() -> void:
	if not ghost or not ghost_valid:
		return

	var piece: StaticBody3D = PIECE_SCENES[equipped_piece].instantiate()
	get_tree().current_scene.add_child(piece)
	piece.global_position = ghost.global_position
	piece.global_rotation = ghost.global_rotation

func _remove_piece() -> void:
	var result := _cast_build_ray()
	if result.is_empty():
		return

	var collider: Object = result.get("collider")
	if collider and collider.is_in_group("build_piece"):
		collider.queue_free()

func _build_ray_target() -> Vector3:
	return camera.global_position + camera.global_transform.basis * Vector3(0, 0, -build_range)

func _cast_build_ray() -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	var query := PhysicsRayQueryParameters3D.create(camera.global_position, _build_ray_target())
	query.exclude = [player.get_rid()]
	return space_state.intersect_ray(query)

func _snap_flat(point: Vector3) -> Vector3:
	return Vector3(
		round(point.x / grid_size) * grid_size,
		round(point.y / grid_size) * grid_size,
		round(point.z / grid_size) * grid_size
	)

func _snap_wall(point: Vector3) -> Dictionary:
	var cx: float = round(point.x / grid_size)
	var cz: float = round(point.z / grid_size)
	var fx: float = point.x / grid_size - cx
	var fz: float = point.z / grid_size - cz
	var y: float = round(point.y / grid_size) * grid_size

	if abs(fx) >= abs(fz):
		var edge_x: float = (cx + (0.5 if fx >= 0.0 else -0.5)) * grid_size
		return {"position": Vector3(edge_x, y, (cz - 0.5) * grid_size), "rotation": -PI / 2.0}
	else:
		var edge_z: float = (cz + (0.5 if fz >= 0.0 else -0.5)) * grid_size
		return {"position": Vector3((cx - 0.5) * grid_size, y, edge_z), "rotation": 0.0}

func _process(_delta: float) -> void:
	if menu_open or not ghost:
		return

	var result := _cast_build_ray()
	var target_point: Vector3 = result.position if result else _build_ray_target()
	var in_range: bool = not result.is_empty()

	var snapped: Vector3
	var rot_y: float

	if equipped_piece == "wall":
		var placement: Dictionary = _snap_wall(target_point)
		snapped = placement["position"]
		rot_y = placement["rotation"]
	else:
		snapped = _snap_flat(target_point)
		rot_y = 0.0

	ghost.global_position = snapped
	ghost.global_rotation = Vector3(0, rot_y, 0)
	ghost_valid = in_range and not _has_overlap(snapped)
	ghost_mesh.material_override = valid_material if ghost_valid else invalid_material

func _has_overlap(at: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	var shape_query := PhysicsShapeQueryParameters3D.new()
	shape_query.shape = ghost_shape
	shape_query.transform = Transform3D(ghost.global_transform.basis, at)
	shape_query.exclude = [ghost.get_rid()]

	for hit in space_state.intersect_shape(shape_query):
		var collider: Object = hit.get("collider")
		if collider and collider.is_in_group("build_piece"):
			return true
	return false
