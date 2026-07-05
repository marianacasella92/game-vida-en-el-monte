extends Node

signal planted(plot)
signal harvested(plot)
signal state_changed(plot, state)

@export var crop_growth_time: float = 8.0

const GROWTH_STAGE_SCENES: Array[PackedScene] = [
	preload("res://assets/farm/Carrot_1.fbx"),
	preload("res://assets/farm/Carrot_2.fbx"),
	preload("res://assets/farm/Carrot_3.fbx"),
	preload("res://assets/farm/Carrot_4.fbx"),
]

var plantables: Array = []

func _ready() -> void:
	add_to_group("crop_manager")
	# register existing build pieces that are garden plots
	for piece in get_tree().get_nodes_in_group("build_piece"):
		if piece.has_meta("piece_category") and piece.get_meta("piece_category", "") == "garden":
			register_plantable(piece)

func register_plantable(node: Node) -> void:
	if plantables.has(node):
		return
	plantables.append(node)

func unregister_plantable(node: Node) -> void:
	plantables.erase(node)

func interact(plot: Node, tool_id: String, inventory=null) -> void:
	var state: String = plot.get_meta("crop_state", "empty")
	if state == "empty" and tool_id == "seed":
		set_plot_state(plot, "growing", Time.get_unix_time_from_system())
		if inventory:
			inventory.remove_item(inventory.selected_slot)
		emit_signal("planted", plot)
		emit_signal("state_changed", plot, "growing")
	elif state == "ready":
		set_plot_state(plot, "empty", 0)
		emit_signal("harvested", plot)
		emit_signal("state_changed", plot, "empty")
	else:
		# nothing to do (growing or missing seed)
		pass

func set_plot_state(plot: Node, state: String, started_at: float = 0.0) -> void:
	plot.set_meta("crop_state", state)
	plot.set_meta("crop_started_at", started_at)

	match state:
		"empty":
			_set_plant_stage(plot, -1)
		"growing":
			_set_plant_stage(plot, 0)
		"ready":
			_set_plant_stage(plot, GROWTH_STAGE_SCENES.size())

	# visual update: prefer material_override if mesh exists
	var mesh: MeshInstance3D = plot.get_node_or_null("MeshInstance3D")
	if mesh:
		var mat: StandardMaterial3D = null
		if mesh.material_override:
			mat = mesh.material_override
		else:
			mat = StandardMaterial3D.new()
			mesh.material_override = mat
		match state:
			"empty":
				mat.albedo_color = Color(1, 1, 1)
			"growing":
				mat.albedo_color = Color(0.95, 0.85, 0.6)
			"ready":
				mat.albedo_color = Color(0.8, 0.95, 0.6)

	var label: Label3D = plot.get_node_or_null("StateLabel")
	if not label:
		label = Label3D.new()
		label.name = "StateLabel"
		label.position = Vector3(0, 0.6, 0)
		plot.add_child(label)
	match state:
		"empty":
			label.text = "Vacío"
		"growing":
			label.text = "Creciendo"
		"ready":
			label.text = "Listo"

## stage -1 = nada (vacío), 0 = montoncito de tierra recién plantado, 1..N = etapas de GROWTH_STAGE_SCENES
func _set_plant_stage(plot: Node, stage: int) -> void:
	if plot.get_meta("plant_stage", -1) == stage:
		return
	plot.set_meta("plant_stage", stage)
	var existing: Node = plot.get_node_or_null("PlantVisual")
	if existing:
		# free() inmediato, no queue_free(): si no, el nodo viejo sigue vivo
		# hasta fin de frame y el nuevo "PlantVisual" que agrego abajo en esta
		# misma función se renombra solo (ej. "PlantVisual2") para no chocar
		# con el nombre todavía ocupado — y la próxima vez ya no lo encuentro.
		existing.free()

	var elapsed: float = Time.get_unix_time_from_system() - float(plot.get_meta("crop_started_at", 0.0))
	print("[crop] %s -> etapa %d/%d (%.1fs reales desde plantado, total configurado %.1fs)" % [plot.name, stage, GROWTH_STAGE_SCENES.size(), elapsed, crop_growth_time])

	if stage < 0 or stage > GROWTH_STAGE_SCENES.size():
		return

	var visual: Node3D
	if stage == 0:
		visual = _build_mound_visual()
	else:
		visual = GROWTH_STAGE_SCENES[stage - 1].instantiate()
	visual.name = "PlantVisual"
	visual.position = Vector3(0, 0.1, 0)
	plot.add_child(visual)

func _build_mound_visual() -> MeshInstance3D:
	var mound := MeshInstance3D.new()
	var mesh := SphereMesh.new()
	mesh.radius = 0.22
	mesh.height = 0.28
	mound.mesh = mesh
	mound.scale = Vector3(1.0, 0.45, 1.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.35, 0.24, 0.14)
	mound.material_override = mat
	return mound

## Reparte crop_growth_time entre el montoncito (etapa 0) y las N etapas de GROWTH_STAGE_SCENES.
func _stage_for_elapsed(elapsed: float) -> int:
	var total_stages: int = GROWTH_STAGE_SCENES.size() + 1
	var fraction: float = elapsed / crop_growth_time
	return clampi(int(fraction * total_stages), 0, total_stages - 1)

## Restaura una parcela cargada desde el guardado: la vuelve a registrar para
## que CropManager siga tickeándola, y le calcula la etapa visual que le
## corresponde según cuánto tiempo real pasó desde que se plantó (en vez de
## arrancar siempre desde el montoncito).
func restore_plot(plot: Node, state: String, started_at: float) -> void:
	register_plantable(plot)
	if state == "growing":
		var elapsed: float = Time.get_unix_time_from_system() - started_at
		if elapsed >= crop_growth_time:
			set_plot_state(plot, "ready", started_at)
			emit_signal("state_changed", plot, "ready")
		else:
			set_plot_state(plot, "growing", started_at)
			_set_plant_stage(plot, _stage_for_elapsed(elapsed))
	elif state == "ready":
		set_plot_state(plot, "ready", started_at)
	else:
		set_plot_state(plot, "empty", 0)

func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	for plot in plantables.duplicate():
		if not is_instance_valid(plot):
			plantables.erase(plot)
			continue
		var state: String = plot.get_meta("crop_state", "empty")
		if state == "growing":
			var started: float = float(plot.get_meta("crop_started_at", 0.0))
			var elapsed: float = now - started
			if elapsed >= crop_growth_time:
				set_plot_state(plot, "ready", started)
				emit_signal("state_changed", plot, "ready")
			else:
				_set_plant_stage(plot, _stage_for_elapsed(elapsed))

func serialize_plantables() -> Array:
	var result: Array = []
	for plot in plantables:
		if not is_instance_valid(plot):
			continue
		result.append({
			"id": plot.get_meta("piece_id", ""),
			"position": [plot.global_position.x, plot.global_position.y, plot.global_position.z],
			"state": plot.get_meta("crop_state", "empty"),
			"started_at": plot.get_meta("crop_started_at", 0.0),
		})
	return result
