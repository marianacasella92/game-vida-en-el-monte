extends Node3D

@export var crop_grid_rows: int = 4
@export var crop_grid_cols: int = 4
@export var crop_grid_cell_size: float = 2.0
@export var crop_grid_origin: Vector3 = Vector3(-4.0, 0.02, 6.0)
@export var debug_show_crop_grid: bool = false
@export var crop_growth_time: float = 8.0

const InteractionPrompt3D := preload("res://scenes/ui/interaction_prompt_3d.tscn")

var crop_slots: Array[Area3D] = []
var camera: Camera3D
var marker_materials: Dictionary = {}

## Prompt compartido para la huerta (una sola instancia que "sigue" a la
## parcela apuntada, en vez de una por parcela) — mismo criterio que ya usa
## build_system.gd para el fantasma/resaltado de demolición: un solo nodo
## roaming es más simple que darle un InteractPrompt propio a cada parcela
## cuando solo se puede estar mirando una a la vez.
var crop_prompt: Node3D

func _ready() -> void:
	camera = get_node("Player/Head/Camera3D")
	if debug_show_crop_grid:
		_build_crop_grid()
	SaveManager.load_game()

	# restore visuals for any placed garden plots loaded by the build system
	_restore_plots_visuals()
	Hotbar.inventory_changed.connect(_on_inventory_changed)
	_on_inventory_changed()

	crop_prompt = InteractionPrompt3D.instantiate()
	add_child(crop_prompt)
	crop_prompt.hide_prompt()

func _restore_plots_visuals() -> void:
	for piece in get_tree().get_nodes_in_group("build_piece"):
		if piece.has_meta("piece_category") and piece.get_meta("piece_category", "") == "garden":
			var state: String = piece.get_meta("crop_state", "empty")
			var progress: float = float(piece.get_meta("crop_progress", 0.0))
			var watered_until: float = float(piece.get_meta("watered_until", 0.0))
			CropManager.restore_plot(piece, state, progress, watered_until)

func _on_inventory_changed() -> void:
	pass

func _build_crop_grid() -> void:
	var holder := Node3D.new()
	holder.name = "CropGrid"
	add_child(holder)

	marker_materials = {
		"empty": _create_marker_material(Color(0.2, 0.75, 0.25, 0.25)),
		"growing": _create_marker_material(Color(0.95, 0.75, 0.2, 0.6)),
		"ready": _create_marker_material(Color(0.95, 0.25, 0.2, 0.75)),
	}

	var mesh := PlaneMesh.new()
	mesh.size = Vector2(crop_grid_cell_size * 0.8, crop_grid_cell_size * 0.8)

	for row in range(crop_grid_rows):
		for col in range(crop_grid_cols):
			var slot := Area3D.new()
			slot.name = "CropSlot_%d_%d" % [row, col]
			slot.position = crop_grid_origin + Vector3(col * crop_grid_cell_size, 0.0, row * crop_grid_cell_size)
			slot.add_to_group("crop_slot")
			holder.add_child(slot)

			var shape := CollisionShape3D.new()
			var sphere := SphereShape3D.new()
			sphere.radius = 0.8
			shape.shape = sphere
			slot.add_child(shape)

			var marker := MeshInstance3D.new()
			marker.name = "Marker"
			marker.mesh = mesh
			marker.rotation_degrees.x = -90.0
			slot.add_child(marker)

			var label := Label3D.new()
			label.name = "StateLabel"
			label.text = "Vacío"
			label.position.y = 0.35
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.modulate = Color.WHITE
			slot.add_child(label)

			crop_slots.append(slot)
			_set_slot_state(slot, "empty")

func _process(delta: float) -> void:
	var now := Time.get_ticks_msec() / 1000.0
	for slot in crop_slots:
		if slot.get_meta("crop_state", "empty") == "growing":
			var started_at: float = slot.get_meta("crop_started_at", now)
			if now - started_at >= crop_growth_time:
				_set_slot_state(slot, "ready")

	# placed garden pieces are handled by CropManager singleton
	_update_crop_prompt()

## Prompt de interacción para la parcela apuntada, con la misma imagen real
## de tecla que ya usan cama/escritorio (interaction_prompt_3d.tscn) — antes
## la huerta no mostraba ningún prompt, ni siquiera el rectángulo viejo.
## Cosechar usa la tecla "interact" (E, igual que el resto); sembrar/regar son
## de herramienta (click izquierdo), que no tiene una acción con nombre en
## InputMap para resolver sola — por eso el ícono "left_mouse" se pasa
## directo en vez de leerlo de InputMap.
func _update_crop_prompt() -> void:
	if _crop_prompt_blocked():
		crop_prompt.hide_prompt()
		return

	var result := _cast_crop_ray()
	if result.is_empty():
		crop_prompt.hide_prompt()
		return

	var collider: Object = result.get("collider")
	if not (collider and collider is Node3D and collider.has_meta("piece_category") and collider.get_meta("piece_category", "") == "garden"):
		crop_prompt.hide_prompt()
		return

	var plot: Node3D = collider
	var state: String = plot.get_meta("crop_state", "empty")
	var player := get_tree().get_first_node_in_group("player")
	var tool_id: String = player.current_tool_id if player else ""

	var action_text := ""
	var key_icon := ""
	match state:
		"ready":
			action_text = "Cosechar"
		"empty":
			if tool_id == "seed":
				action_text = "Sembrar"
				key_icon = "left_mouse"
		"growing":
			if tool_id == "watering_can":
				action_text = "Regar"
				key_icon = "left_mouse"

	if action_text == "":
		crop_prompt.hide_prompt()
		return

	crop_prompt.global_position = plot.global_position + Vector3(0, 0.6, 0)
	crop_prompt.show_prompt(action_text, key_icon)

## Mismas guardas que ya usan _handle_tool_use_click()/otros sistemas
## modales — no tiene sentido mostrar el prompt de la huerta mientras se está
## construyendo, trabajando, o con una pantalla modal abierta encima.
func _crop_prompt_blocked() -> bool:
	var build_system := get_tree().get_first_node_in_group("build_system")
	if build_system and build_system.equipped_category != "none":
		return true
	var work_system := get_tree().get_first_node_in_group("work_system")
	if work_system and work_system.is_working:
		return true
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

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		_handle_interact()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tool_use_click()

## Tecla E: interactuar/agarrar. No depende de la herramienta equipada — sirve
## para interactuables genéricos (ej. el escritorio) y para cosechar un
## cultivo listo. Plantar/regar es acción de herramienta y va por click
## izquierdo (_handle_tool_use_click), no acá.
func _handle_interact() -> void:
	print("[crop] interact pressed")
	var target: Node = InteractionManager.get_from_ray(camera, 4.0)
	if target:
		print("[crop] ray hit interactable: %s" % target)
		if target.has_method("interact"):
			var player := get_tree().get_first_node_in_group("player")
			var tool_id: String = player.current_tool_id if player else ""
			target.interact(tool_id, player)
			return
	# fallback to previous ray logic for legacy crop slots and build pieces
	var result := _cast_crop_ray()
	if not result.is_empty():
		var collider: Object = result.get("collider")
		print("[crop] ray hit: %s" % collider)
		if collider and collider is Node:
			var target2: Node = collider
			if target2.has_meta("piece_category") and target2.get_meta("piece_category", "") == "garden":
				print("[crop] hit garden piece directly: %s -> cosechar si está lista" % target2.name)
				CropManager.harvest_plot(target2, Hotbar)
				return
			if target2 is Area3D and target2.is_in_group("crop_slot"):
				print("[crop] hit crop slot directly")
				_interact_with_slot(target2)
				return
			if target2.get_parent() and target2.get_parent().is_in_group("crop_slot"):
				print("[crop] hit child of crop slot")
				_interact_with_slot(target2.get_parent())
				return

	for slot in crop_slots:
		if _slot_is_near_player(slot):
			print("[crop] using proximity fallback for slot %s" % slot.name)
			_interact_with_slot(slot)
			return

	print("[crop] no slot reached")

## Click izquierdo: usar la herramienta equipada (plantar semilla, regar,
## comer) sobre la parcela apuntada o sobre una misma (comer no apunta a
## nada). Si el sistema de construcción está usando el click (colocando o
## destruyendo una pieza), no hace nada — ese click ya es suyo.
func _handle_tool_use_click() -> void:
	var build_system: Node = get_tree().get_first_node_in_group("build_system")
	if build_system and build_system.equipped_category != "none":
		return

	var equipped_id: String = Hotbar.get_selected_item().get("id", "")
	if PlayerNeeds.try_eat(equipped_id):
		Hotbar.remove_item(Hotbar.selected_slot)
		print("[needs] comió %s, hambre=%.0f" % [equipped_id, PlayerNeeds.hunger])
		return

	var result := _cast_crop_ray()
	if result.is_empty():
		return
	var collider: Object = result.get("collider")
	if collider and collider is Node and collider.has_meta("piece_category") and collider.get_meta("piece_category", "") == "garden":
		var player := get_tree().get_first_node_in_group("player")
		var tool_id: String = player.current_tool_id if player else ""
		print("[crop] click en %s con tool=%s" % [collider.name, tool_id])
		CropManager.use_tool(collider, tool_id, Hotbar)

func _interact_with_slot(slot: Area3D) -> void:
	var state: String = slot.get_meta("crop_state", "empty")
	var player: Node = get_tree().get_first_node_in_group("player")
	var tool_id: String = player.current_tool_id if player else ""
	print("[crop] slot %s state=%s tool=%s selected_slot=%d" % [slot.name, state, tool_id, Hotbar.selected_slot])

	if state == "empty" and tool_id == "seed":
		_set_slot_state(slot, "growing", Time.get_ticks_msec() / 1000.0)
		Hotbar.remove_item(Hotbar.selected_slot)
		print("[crop] planted")
	elif state == "ready":
		_set_slot_state(slot, "empty")
		print("[crop] harvested")
	elif state == "empty":
		print("[crop] need seed")
	else:
		print("[crop] still growing")

func _cast_crop_ray() -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	var origin: Vector3 = camera.global_position
	var target: Vector3 = origin + camera.global_transform.basis * Vector3(0, 0, -4.0)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [get_tree().get_first_node_in_group("player").get_rid()]
	# allow hitting Area3D nodes (crop slots) as well as physics bodies
	query.collide_with_areas = true
	query.collide_with_bodies = true
	return space_state.intersect_ray(query)

func _slot_is_near_player(slot: Area3D) -> bool:
	var player: Node3D = get_tree().get_first_node_in_group("player")
	if not player:
		return false
	var dist: float = slot.global_position.distance_to(player.global_position)
	# debug: print vertical and horizontal offset for tuning proximity
	var vertical: float = abs(slot.global_position.y - player.global_position.y)
	var horizontal: float = Vector2(slot.global_position.x, slot.global_position.z).distance_to(Vector2(player.global_position.x, player.global_position.z))
	print("[crop] proximity check %s dist=%.2f horiz=%.2f vert=%.2f" % [slot.name, dist, horizontal, vertical])
	return dist <= 2.2

func _create_marker_material(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color = color
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return material

func _set_slot_state(slot: Area3D, state: String, started_at: float = 0.0) -> void:
	slot.set_meta("crop_state", state)
	slot.set_meta("crop_started_at", started_at)
	var marker: MeshInstance3D = slot.get_node("Marker")
	var label: Label3D = slot.get_node("StateLabel")
	marker.material_override = marker_materials.get(state, marker_materials["empty"])
	match state:
		"empty":
			label.text = "Vacío"
		"growing":
			label.text = "Creciendo"
		"ready":
			label.text = "Listo"

func serialize_crops() -> Array:
	var result: Array = []
	for slot in crop_slots:
		result.append({
			"state": slot.get_meta("crop_state", "empty"),
			"started_at": slot.get_meta("crop_started_at", 0.0),
		})
	return result

func load_crops(data: Array) -> void:
	for index in range(min(data.size(), crop_slots.size())):
		var entry: Dictionary = data[index]
		var state: String = entry.get("state", "empty")
		var started_at: float = float(entry.get("started_at", 0.0))
		_set_slot_state(crop_slots[index], state, started_at)
		if state == "growing" and Time.get_ticks_msec() / 1000.0 - started_at >= crop_growth_time:
			_set_slot_state(crop_slots[index], "ready")
