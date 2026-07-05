extends Node

signal planted(plot)
signal harvested(plot)
signal state_changed(plot, state)

@export var crop_growth_time: float = 8.0
## Cuánto dura el efecto de un riego (segundos reales) antes de necesitar regar
## de nuevo. GDD 4.5: regadera manual, nivel 1 de riego — sin penalización dura,
## si no se riega el cultivo simplemente se estanca (no avanza), no muere.
@export var watering_duration: float = 6.0

const GROWTH_STAGE_SCENES: Array[PackedScene] = [
	preload("res://assets/farm/Carrot_1.fbx"),
	preload("res://assets/farm/Carrot_2.fbx"),
	preload("res://assets/farm/Carrot_3.fbx"),
	preload("res://assets/farm/Carrot_4.fbx"),
]

var plantables: Array = []

## tool_id que puede actuar sobre una parcela en cada crop_state, y a qué
## acción llama. Cosechar es la excepción — no depende de la herramienta
## equipada (podés cosechar con cualquier cosa en la mano), así que se
## chequea aparte en interact(), antes de mirar esta tabla.
##
## Para agregar una herramienta nueva (ej. "hose" para el nivel 2 de riego del
## GDD 4.5, o cualquier acción futura sobre un cultivo) alcanza con sumar una
## entrada acá — interact() no necesita una rama de if/elif nueva, y las
## acciones existentes no se tocan.
##
## No es const porque Callable(self, ...) recién existe una vez que el nodo
## está en el árbol — se arma en _ready().
var _state_actions: Dictionary = {}

func _ready() -> void:
	add_to_group("crop_manager")
	_state_actions = {
		"empty": {"seed": plant_seed},
		"growing": {"watering_can": water_plot},
	}
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

## Punto de entrada genérico (usado por interactuables tipo InteractionManager,
## donde una sola acción — la tecla E — tiene que hacer "lo que corresponda").
## world.gd, en cambio, llama a use_tool()/harvest_plot() por separado, porque
## en este proyecto usar herramienta (click) y cosechar (E) son inputs distintos.
func interact(plot: Node, tool_id: String, inventory=null) -> void:
	var state: String = plot.get_meta("crop_state", "empty")
	if state == "ready":
		harvest_plot(plot, inventory)
		return
	use_tool(plot, tool_id, inventory)

## Intenta usar la herramienta equipada sobre la parcela (plantar semilla,
## regar). No cosecha nunca, aunque la parcela esté lista — eso es
## harvest_plot(), a propósito, para poder engancharlos a inputs distintos.
func use_tool(plot: Node, tool_id: String, inventory=null) -> void:
	var state: String = plot.get_meta("crop_state", "empty")
	var handler: Callable = _state_actions.get(state, {}).get(tool_id, Callable())
	if handler.is_valid():
		handler.call(plot, inventory)
	# si no hay handler (herramienta equivocada, o nada equipado), no pasa nada
	# — sin penalización dura, consistente con el resto del proyecto.

## Todas las acciones de abajo (plant_seed, water_plot, harvest_plot) son
## públicas y autocontenidas: cada una hace su propia transición de estado,
## actualiza visuales y emite sus señales. Así, algo que no sea el jugador
## (ej. un futuro sistema de riego automatizado tickeando en _process, o una
## UI de depuración) puede llamarlas directo, sin pasar por interact()/tool_id.

func plant_seed(plot: Node, inventory=null) -> void:
	if plot.get_meta("crop_state", "empty") != "empty":
		return
	plot.set_meta("crop_progress", 0.0)
	plot.set_meta("watered_until", 0.0)
	plot.set_meta("is_watered_cache", false)
	set_plot_state(plot, "growing", Time.get_unix_time_from_system())
	_update_growing_label(plot, false)
	if inventory:
		inventory.remove_item(inventory.selected_slot)
	emit_signal("planted", plot)
	emit_signal("state_changed", plot, "growing")

func water_plot(plot: Node, _inventory=null) -> void:
	if plot.get_meta("crop_state", "empty") != "growing":
		return
	plot.set_meta("watered_until", Time.get_unix_time_from_system() + watering_duration)
	print("[crop] %s regada, sigue creciendo por %.1fs más" % [plot.name, watering_duration])

## El segundo parámetro no se usa acá (cosechar entrega el ítem vía
## Backpack.add_item(), no depende de qué hotbar se pase) — se mantiene por
## firma uniforme con plant_seed()/water_plot(), que sí lo necesitan.
func harvest_plot(plot: Node, _inventory=null) -> void:
	if plot.get_meta("crop_state", "empty") != "ready":
		return # solo se puede cosechar si está lista; llamable desde cualquier lado, no solo desde interact()
	set_plot_state(plot, "empty", 0)
	plot.set_meta("crop_progress", 0.0)
	plot.set_meta("watered_until", 0.0)
	Backpack.add_item("carrot", "Zanahoria")
	emit_signal("harvested", plot)
	emit_signal("state_changed", plot, "empty")

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

## Refleja si a la parcela le falta agua, sin pisar el label en cada frame:
## solo lo actualiza cuando el estado regada/seca realmente cambia.
func _update_growing_label(plot: Node, is_watered: bool) -> void:
	var label: Label3D = plot.get_node_or_null("StateLabel")
	if label:
		label.text = "Creciendo" if is_watered else "Necesita agua"

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

	var progress: float = float(plot.get_meta("crop_progress", 0.0))
	print("[crop] %s -> etapa %d/%d (%.1fs de riego acumulado / %.1fs necesarios)" % [plot.name, stage, GROWTH_STAGE_SCENES.size(), progress, crop_growth_time])

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
func _stage_for_progress(progress: float) -> int:
	var total_stages: int = GROWTH_STAGE_SCENES.size() + 1
	var fraction: float = progress / crop_growth_time
	return clampi(int(fraction * total_stages), 0, total_stages - 1)

## Restaura una parcela cargada desde el guardado: la vuelve a registrar para
## que CropManager siga tickeándola, con el progreso de riego acumulado tal
## cual estaba (no se recalcula por tiempo real transcurrido, porque el
## crecimiento depende de riego manual, no solo del reloj).
func restore_plot(plot: Node, state: String, progress: float, watered_until: float) -> void:
	register_plantable(plot)
	plot.set_meta("crop_progress", progress)
	plot.set_meta("watered_until", watered_until)
	var is_watered: bool = Time.get_unix_time_from_system() < watered_until
	plot.set_meta("is_watered_cache", is_watered)
	match state:
		"growing":
			set_plot_state(plot, "growing", plot.get_meta("crop_started_at", 0.0))
			_update_growing_label(plot, is_watered)
			_set_plant_stage(plot, _stage_for_progress(progress))
		"ready":
			set_plot_state(plot, "ready", 0.0)
		_:
			set_plot_state(plot, "empty", 0.0)

func _process(delta: float) -> void:
	var now := Time.get_unix_time_from_system()
	for plot in plantables.duplicate():
		if not is_instance_valid(plot):
			plantables.erase(plot)
			continue
		if plot.get_meta("crop_state", "empty") != "growing":
			continue

		var watered_until: float = float(plot.get_meta("watered_until", 0.0))
		var is_watered: bool = now < watered_until
		if is_watered != plot.get_meta("is_watered_cache", false):
			plot.set_meta("is_watered_cache", is_watered)
			_update_growing_label(plot, is_watered)

		if not is_watered:
			continue # sin agua: se estanca, no avanza (pero tampoco retrocede)

		var progress: float = float(plot.get_meta("crop_progress", 0.0)) + delta
		plot.set_meta("crop_progress", progress)
		if progress >= crop_growth_time:
			set_plot_state(plot, "ready", plot.get_meta("crop_started_at", 0.0))
			emit_signal("state_changed", plot, "ready")
		else:
			_set_plant_stage(plot, _stage_for_progress(progress))
