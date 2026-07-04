extends Node3D

@export var build_range: float = 10.0
@export var grid_size: float = 2.0
@export var wall_height: float = 3.0

## category_id -> {"label": String, "variants": {variant_id -> {"label": String, "scene": PackedScene}}}
## La categoría define CÓMO se posiciona la pieza (ver _process); la variante
## solo define QUÉ escena se instancia. Agregar una puerta, una ventana o una
## esquina nueva es sumar una entrada acá, sin tocar la lógica de snap.
const CATALOG := {
	"wall": {
		"label": "Pared",
		"variants": {
			"straight": {"label": "Recta", "scene": preload("res://scenes/build/wall.tscn")},
			"door": {"label": "Puerta", "scene": preload("res://scenes/build/wall_door.tscn")},
			"window": {"label": "Ventana", "scene": preload("res://scenes/build/wall_window.tscn")},
		},
	},
	"floor": {
		"label": "Piso",
		"variants": {
			"plain": {"label": "Piso", "scene": preload("res://scenes/build/floor.tscn")},
		},
	},
	"roof": {
		"label": "Techo",
		"variants": {
			"flat": {"label": "Plano", "scene": preload("res://scenes/build/roof.tscn")},
		},
	},
}

@onready var camera: Camera3D = get_node("../Head/Camera3D")
@onready var player: CharacterBody3D = get_parent()
@onready var radial_menu: Control = $RadialMenuLayer/Wheel

var equipped_category: String = "none"
var equipped_variant: String = ""
var ghost: StaticBody3D
var ghost_meshes: Array[MeshInstance3D] = []
var ghost_shape: Shape3D
var ghost_valid: bool = false
var menu_open: bool = false
var manual_flip: bool = false
var floor_cells: Dictionary = {}

var valid_material := StandardMaterial3D.new()
var invalid_material := StandardMaterial3D.new()

func _ready() -> void:
	valid_material.albedo_color = Color(0.2, 1.0, 0.2, 0.5)
	valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	valid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	invalid_material.albedo_color = Color(1.0, 0.2, 0.2, 0.5)
	invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	invalid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	radial_menu.setup(_menu_catalog())
	_spawn_ghost()

func _menu_catalog() -> Dictionary:
	var menu: Dictionary = {}
	for category_id in CATALOG:
		var variants: Dictionary = {}
		for variant_id in CATALOG[category_id]["variants"]:
			variants[variant_id] = CATALOG[category_id]["variants"][variant_id]["label"]
		menu[category_id] = {"label": CATALOG[category_id]["label"], "variants": variants}
	return menu

func _piece_scene(category: String, variant: String) -> PackedScene:
	return CATALOG[category]["variants"][variant]["scene"]

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("build_menu"):
		menu_open = true
		if ghost:
			ghost.visible = false
		radial_menu.open()
	elif event.is_action_released("build_menu"):
		menu_open = false
		var choice: Dictionary = radial_menu.close()
		if not choice.is_empty():
			equipped_category = choice["category"]
			equipped_variant = choice["variant"]
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

	if equipped_category == "none":
		return

	ghost = _piece_scene(equipped_category, equipped_variant).instantiate()
	add_child(ghost)

	ghost_meshes = _find_mesh_instances(ghost)
	for mesh in ghost_meshes:
		mesh.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF

	var collision: CollisionShape3D = ghost.get_node("CollisionShape3D")
	ghost_shape = collision.shape
	collision.disabled = true
	ghost.collision_layer = 0
	ghost.collision_mask = 0

func _cell_key(x: float, z: float) -> Vector2i:
	return Vector2i(int(round(x / grid_size)), int(round(z / grid_size)))

func _place_piece() -> void:
	if not ghost or not ghost_valid:
		return

	var piece: StaticBody3D = _piece_scene(equipped_category, equipped_variant).instantiate()
	get_tree().current_scene.add_child(piece)
	piece.global_position = ghost.global_position
	piece.global_rotation = ghost.global_rotation

	if equipped_category == "floor":
		floor_cells[_cell_key(piece.global_position.x, piece.global_position.z)] = true

func _remove_piece() -> void:
	var result := _cast_build_ray()
	if result.is_empty():
		return

	var collider: Object = result.get("collider")
	if collider and collider.is_in_group("build_piece"):
		if collider.get_meta("piece_category", "") == "floor":
			floor_cells.erase(_cell_key(collider.global_position.x, collider.global_position.z))
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

func _cell_has_floor(x: float, z: float) -> bool:
	return floor_cells.has(_cell_key(x, z))

## Decide hacia qué lado del eje positivo (norte o este) debe mirar la cara linda,
## mirando únicamente las dos celdas fijas a los lados del borde — nunca la posición
## del jugador — para que el resultado no cambie según desde dónde se apunte.
func _face_positive_side(positive_x: float, positive_z: float, negative_x: float, negative_z: float) -> bool:
	var positive_has_floor: bool = _cell_has_floor(positive_x, positive_z)
	var negative_has_floor: bool = _cell_has_floor(negative_x, negative_z)
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
		var face_east: bool = _face_positive_side(edge_x + grid_size / 2.0, cz * grid_size, edge_x - grid_size / 2.0, cz * grid_size) != manual_flip
		var edge_z: float = (cz + 0.5) * grid_size if face_east else (cz - 0.5) * grid_size
		var rot: float = (PI / 2.0) if face_east else (-PI / 2.0)
		return {"position": Vector3(edge_x, y, edge_z), "rotation": rot}
	else:
		# Pared corriendo en X, en el borde norte/sur de la celda (cx,cz).
		var edge_z: float = (cz + (0.5 if fz >= 0.0 else -0.5)) * grid_size
		var face_north: bool = _face_positive_side(cx * grid_size, edge_z + grid_size / 2.0, cx * grid_size, edge_z - grid_size / 2.0) != manual_flip
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

	if equipped_category == "wall":
		var placement: Dictionary = _snap_wall(target_point)
		snapped = placement["position"]
		rot_y = placement["rotation"]
	elif equipped_category == "roof":
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
