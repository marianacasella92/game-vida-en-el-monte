extends Node3D

@export var build_range: float = 10.0
@export var grid_size: float = 2.0
@export var wall_height: float = 3.0

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
var ghost_meshes: Array[MeshInstance3D] = []
var ghost_shape: Shape3D
var ghost_valid: bool = false
var menu_open: bool = false
var manual_flip: bool = false

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
	elif event.is_action_pressed("build_flip") and not menu_open:
		manual_flip = not manual_flip
	elif event is InputEventMouseButton and event.pressed and not menu_open:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_place_piece()
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_remove_piece()

func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_find_mesh_instances(child))
	return found

func _spawn_ghost() -> void:
	if ghost:
		ghost.queue_free()
		ghost = null
		ghost_meshes = []
		ghost_shape = null

	manual_flip = false

	if equipped_piece == "none":
		return

	ghost = PIECE_SCENES[equipped_piece].instantiate()
	add_child(ghost)

	ghost_meshes = _find_mesh_instances(ghost)
	for mesh in ghost_meshes:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

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

func _snap_roof(point: Vector3) -> Vector3:
	var flat: Vector3 = _snap_flat(point)
	flat.y = wall_height
	return flat

func _cell_has_floor(center: Vector3) -> bool:
	var space_state := get_world_3d().direct_space_state
	var shape := SphereShape3D.new()
	shape.radius = grid_size * 0.3
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform = Transform3D(Basis(), center + Vector3(0, 0.05, 0))

	for hit in space_state.intersect_shape(query, 8):
		var collider: Object = hit.get("collider")
		if collider and collider.is_in_group("build_piece") and collider.get_meta("piece_id", "") == "floor":
			return true
	return false

## Decide hacia qué lado del eje positivo (norte o este) debe mirar la cara linda,
## mirando únicamente las dos celdas fijas a los lados del borde — nunca la posición
## del jugador — para que el resultado no cambie según desde dónde se apunte.
func _face_positive_side(positive_cell: Vector3, negative_cell: Vector3) -> bool:
	var positive_has_floor: bool = _cell_has_floor(positive_cell)
	var negative_has_floor: bool = _cell_has_floor(negative_cell)
	if negative_has_floor and not positive_has_floor:
		return true
	if positive_has_floor and not negative_has_floor:
		return false
	return true

func _snap_wall(point: Vector3) -> Dictionary:
	var cx: float = round(point.x / grid_size)
	var cz: float = round(point.z / grid_size)
	var fx: float = point.x / grid_size - cx
	var fz: float = point.z / grid_size - cz
	var y: float = round(point.y / grid_size) * grid_size

	if abs(fx) >= abs(fz):
		# Pared corriendo en Z, en el borde este/oeste de la celda (cx,cz).
		var edge_x: float = (cx + (0.5 if fx >= 0.0 else -0.5)) * grid_size
		var east_cell := Vector3(edge_x + grid_size / 2.0, y, cz * grid_size)
		var west_cell := Vector3(edge_x - grid_size / 2.0, y, cz * grid_size)
		var face_east: bool = _face_positive_side(east_cell, west_cell) != manual_flip
		var edge_z: float = (cz + 0.5) * grid_size if face_east else (cz - 0.5) * grid_size
		var rot: float = (PI / 2.0) if face_east else (-PI / 2.0)
		return {"position": Vector3(edge_x, y, edge_z), "rotation": rot}
	else:
		# Pared corriendo en X, en el borde norte/sur de la celda (cx,cz).
		var edge_z: float = (cz + (0.5 if fz >= 0.0 else -0.5)) * grid_size
		var north_cell := Vector3(cx * grid_size, y, edge_z + grid_size / 2.0)
		var south_cell := Vector3(cx * grid_size, y, edge_z - grid_size / 2.0)
		var face_north: bool = _face_positive_side(north_cell, south_cell) != manual_flip
		var edge_x: float = (cx - 0.5) * grid_size if face_north else (cx + 0.5) * grid_size
		var rot: float = 0.0 if face_north else PI
		return {"position": Vector3(edge_x, y, edge_z), "rotation": rot}

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
	elif equipped_piece == "roof":
		snapped = _snap_roof(target_point)
		rot_y = 0.0
	else:
		snapped = _snap_flat(target_point)
		rot_y = 0.0

	ghost.global_position = snapped
	ghost.global_rotation = Vector3(0, rot_y, 0)
	ghost_valid = in_range and not _has_overlap(snapped)
	var tint: StandardMaterial3D = valid_material if ghost_valid else invalid_material
	for mesh in ghost_meshes:
		mesh.material_override = tint

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
