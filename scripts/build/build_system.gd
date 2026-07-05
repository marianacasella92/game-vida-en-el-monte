extends Node3D

@export var build_range: float = 10.0
@export var grid_size: float = 2.0
@export var wall_height: float = 3.0

## category_id -> {"label": String, "variants": {variant_id -> {"label": String, "scene": PackedScene, "requires_item": String opcional}}}
## La categoría define CÓMO se posiciona la pieza (ver _process); la variante
## solo define QUÉ escena se instancia. Agregar una puerta, una ventana o una
## esquina nueva es sumar una entrada acá, sin tocar la lógica de snap.
## "requires_item" (opcional) es el id de Economy.purchased_items que hace
## falta tener comprado en el marketplace para que la variante aparezca en el
## catálogo (ver _menu_catalog).
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
			"center": {"label": "Faldón A", "scene": preload("res://scenes/build/roof_center.tscn")},
			"center_mirror": {"label": "Faldón B", "scene": preload("res://scenes/build/roof_center_mirror.tscn")},
			"l": {"label": "Remate Izq.", "scene": preload("res://scenes/build/roof_l.tscn")},
			"r": {"label": "Remate Der.", "scene": preload("res://scenes/build/roof_r.tscn")},
			"corner": {"label": "Esquina", "scene": preload("res://scenes/build/roof_corner.tscn")},
			"middle": {"label": "Cumbrera", "scene": preload("res://scenes/build/roof_middle.tscn")},
		},
	},
	"desk": {
		"label": "Escritorio",
		"variants": {
			"plain": {"label": "Escritorio", "scene": preload("res://scenes/build/desk.tscn")},
		},
	},
	"decor": {
		"label": "Decoración",
		"variants": {
			"crate": {"label": "Cajón de madera", "scene": preload("res://scenes/build/decor_crate.tscn"), "requires_item": "crate"},
		},
	},
	"garden": {
		"label": "Huerta",
		"variants": {
			"plot": {"label": "Parcela simple", "scene": preload("res://scenes/build/garden_plot.tscn")},
		},
	},
	"bed": {
		"label": "Cama",
		"variants": {
			"plain": {"label": "Cama simple", "scene": preload("res://scenes/build/bed.tscn"), "requires_item": "bed"},
		},
	},
}

@onready var camera: Camera3D = get_node("../Head/Camera3D")
@onready var player: CharacterBody3D = get_parent()
@onready var catalog_menu: Control = $BuildMenuLayer/Catalog
@onready var work_system: Node = get_node("../WorkSystem")
@onready var phone_system: Node = get_node("../PhoneSystem")
@onready var inventory_system: Node = get_node("../InventorySystem")

var equipped_category: String = "none"
var equipped_variant: String = ""
var ghost: StaticBody3D
var ghost_meshes: Array[MeshInstance3D] = []
var ghost_shape: Shape3D
var ghost_valid: bool = false
var menu_open: bool = false
var manual_flip: bool = false
var rotation_steps: int = 0
var floor_cells: Dictionary = {}

## "Destruir" es una herramienta más del catálogo (como equipar una pared),
## no un click derecho suelto: hay que elegirla a propósito en el menú (G).
var demolish_hover: Node = null
var demolish_hover_materials: Dictionary = {} # MeshInstance3D -> Material original

var valid_material := StandardMaterial3D.new()
var invalid_material := StandardMaterial3D.new()

func _ready() -> void:
	add_to_group("build_system")

	valid_material.albedo_color = Color(0.2, 1.0, 0.2, 0.5)
	valid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	valid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	invalid_material.albedo_color = Color(1.0, 0.2, 0.2, 0.5)
	invalid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	invalid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	catalog_menu.setup(_menu_catalog())
	catalog_menu.piece_chosen.connect(_on_piece_chosen)
	catalog_menu.cancelled.connect(_close_catalog)
	_spawn_ghost()

func _menu_catalog() -> Dictionary:
	var menu: Dictionary = {}
	for category_id in CATALOG:
		var variants: Dictionary = {}
		for variant_id in CATALOG[category_id]["variants"]:
			var variant: Dictionary = CATALOG[category_id]["variants"][variant_id]
			var requires_item: String = variant.get("requires_item", "")
			if requires_item != "" and not Economy.purchased_items.has(requires_item):
				continue
			variants[variant_id] = variant["label"]
		if variants.is_empty():
			continue
		menu[category_id] = {"label": CATALOG[category_id]["label"], "variants": variants}
	menu["demolish"] = {"label": "Destruir", "variants": {}}
	return menu

func _piece_scene(category: String, variant: String) -> PackedScene:
	return CATALOG[category]["variants"][variant]["scene"]

func _unhandled_input(event: InputEvent) -> void:
	if work_system.is_working or phone_system.is_open or inventory_system.is_open:
		return
	if event.is_action_pressed("ui_cancel"):
		if menu_open:
			_close_catalog()
		else:
			_exit_build_mode()
		return
	if event.is_action_pressed("build_menu"):
		if menu_open:
			_close_catalog()
		else:
			_open_catalog()
	elif menu_open:
		return
	elif event.is_action_pressed("build_flip"):
		manual_flip = not manual_flip
	elif event.is_action_pressed("build_rotate"):
		if equipped_category == "roof" or equipped_category == "desk" or equipped_category == "decor":
			rotation_steps = (rotation_steps + 1) % 4
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if equipped_category == "demolish":
			_demolish_hovered()
		else:
			_place_piece()

func _open_catalog() -> void:
	menu_open = true
	catalog_menu.setup(_menu_catalog())
	if ghost:
		ghost.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	catalog_menu.open()

func _close_catalog() -> void:
	menu_open = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	catalog_menu.close()
	if ghost:
		ghost.visible = true

func _exit_build_mode() -> void:
	equipped_category = "none"
	equipped_variant = ""
	menu_open = false
	manual_flip = false
	rotation_steps = 0
	_clear_demolish_highlight()
	if ghost:
		ghost.visible = false
		ghost.queue_free()
		ghost = null
		ghost_meshes = []
		ghost_shape = null
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	catalog_menu.close()

func _on_piece_chosen(category: String, variant: String) -> void:
	equipped_category = category
	equipped_variant = variant
	_spawn_ghost()
	_close_catalog()

func _find_mesh_instances(node: Node) -> Array[MeshInstance3D]:
	var found: Array[MeshInstance3D] = []
	if node is MeshInstance3D:
		found.append(node)
	for child in node.get_children():
		found.append_array(_find_mesh_instances(child))
	return found

func _spawn_ghost() -> void:
	_clear_demolish_highlight()

	if ghost:
		ghost.queue_free()
		ghost = null
		ghost_meshes = []
		ghost_shape = null

	manual_flip = false
	rotation_steps = 0

	if equipped_category == "none" or equipped_category == "demolish":
		return

	ghost = _piece_scene(equipped_category, equipped_variant).instantiate()
	add_child(ghost)
	# el fantasma es un preview, no una pieza real puesta en el mundo — sacarlo
	# del grupo "build_piece" para que serialize_pieces()/CropManager/etc. no
	# lo confundan con algo colocado de verdad mientras sigue el mouse.
	if ghost.is_in_group("build_piece"):
		ghost.remove_from_group("build_piece")

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
	print("[build] colocada %s/%s en %s — en grupo build_piece=%s" % [equipped_category, equipped_variant, piece.global_position, piece.is_in_group("build_piece")])

	if equipped_category == "floor":
		floor_cells[_cell_key(piece.global_position.x, piece.global_position.z)] = true
	elif equipped_category == "garden":
		CropManager.register_plantable(piece)

func _process_demolish() -> void:
	var result := _cast_build_ray()
	var hovered: Node = null
	if not result.is_empty():
		var collider: Object = result.get("collider")
		if collider and collider is Node and collider.is_in_group("build_piece"):
			hovered = collider

	if hovered == demolish_hover:
		return
	_clear_demolish_highlight()
	demolish_hover = hovered
	if demolish_hover:
		for mesh in _find_mesh_instances(demolish_hover):
			demolish_hover_materials[mesh] = mesh.material_override
			mesh.material_override = invalid_material

func _clear_demolish_highlight() -> void:
	for mesh in demolish_hover_materials:
		if is_instance_valid(mesh):
			mesh.material_override = demolish_hover_materials[mesh]
	demolish_hover_materials.clear()
	demolish_hover = null

func _demolish_hovered() -> void:
	if not demolish_hover:
		return
	var piece := demolish_hover
	_clear_demolish_highlight()
	_refund_piece_contents(piece)
	if piece.get_meta("piece_category", "") == "floor":
		floor_cells.erase(_cell_key(piece.global_position.x, piece.global_position.z))
	piece.queue_free()

## Antes de destruir una pieza, devuelve al inventario lo que tuviera "adentro".
## Por ahora solo aplica a huerta (semilla plantada); nuevas categorías con
## contenido reembolsable se agregan acá con otro if.
func _refund_piece_contents(piece: Node) -> void:
	if piece.get_meta("piece_category", "") == "garden":
		var state: String = piece.get_meta("crop_state", "empty")
		if state == "growing" or state == "ready":
			Backpack.add_item("seed", "Semilla de Zanahoria")
		CropManager.unregister_plantable(piece)

## Usado por SaveManager (autoload/save_manager.gd) para persistir lo construido.
func serialize_pieces() -> Array:
	var result: Array = []
	for piece in get_tree().get_nodes_in_group("build_piece"):
		var entry := {
			"category": piece.get_meta("piece_category", ""),
			"id": piece.get_meta("piece_id", ""),
			"position": [piece.global_position.x, piece.global_position.y, piece.global_position.z],
			"rotation": [piece.global_rotation.x, piece.global_rotation.y, piece.global_rotation.z],
		}
		# include crop metadata for garden pieces if present
		if piece.has_meta("crop_state"):
			entry["meta"] = {
				"crop_state": piece.get_meta("crop_state"),
				"crop_progress": piece.get_meta("crop_progress", 0.0),
				"watered_until": piece.get_meta("watered_until", 0.0),
			}
		result.append(entry)
	return result

func clear_pieces() -> void:
	for piece in get_tree().get_nodes_in_group("build_piece"):
		piece.queue_free()
	floor_cells.clear()

func load_pieces(data: Array) -> void:
	for entry in data:
		var category: String = entry["category"]
		var variant: String = entry["id"]
		var piece: StaticBody3D = _piece_scene(category, variant).instantiate()
		get_tree().current_scene.add_child(piece)

		var pos: Array = entry["position"]
		var rot: Array = entry["rotation"]
		piece.global_position = Vector3(pos[0], pos[1], pos[2])
		piece.global_rotation = Vector3(rot[0], rot[1], rot[2])

		if category == "floor":
			floor_cells[_cell_key(piece.global_position.x, piece.global_position.z)] = true

		# restore planted metadata if present
		if entry.has("meta"):
			var meta: Dictionary = entry["meta"]
			if meta.has("crop_state"):
				piece.set_meta("crop_state", meta.get("crop_state"))
				piece.set_meta("crop_progress", meta.get("crop_progress", 0.0))
				piece.set_meta("watered_until", meta.get("watered_until", 0.0))

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
	if menu_open or work_system.is_working or phone_system.is_open or inventory_system.is_open:
		return

	if equipped_category == "demolish":
		_process_demolish()
		return

	if not ghost:
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
		rot_y = rotation_steps * (PI / 2.0)
	elif equipped_category == "desk" or equipped_category == "decor":
		snapped = _snap_flat(target_point)
		rot_y = rotation_steps * (PI / 2.0)
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
