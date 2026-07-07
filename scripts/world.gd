extends Node3D

## Raíz del mundo: arranque de la partida (cargar guardado, restaurar
## visuales de parcelas) + la interacción del jugador con la huerta (prompt,
## cosechar con E, usar herramienta con click). La lógica de cultivo vive en
## CropManager — acá solo está el "apuntar y actuar" sobre las parcelas.
##
## Nota histórica: hasta el 07/07/2026 este script arrastraba una grilla de
## cultivo legacy completa (crop_slots como Area3D sueltas, anterior a
## CropManager) que solo se activaba con un flag de debug apagado — se borró
## entera. Las parcelas reales son piezas del sistema de construcción
## (piece_category == "garden") y las maneja CropManager.

const InteractionPrompt3D := preload("res://scenes/ui/interaction_prompt_3d.tscn")

var camera: Camera3D

## Prompt compartido para la huerta (una sola instancia que "sigue" a la
## parcela apuntada, en vez de una por parcela) — mismo criterio que ya usa
## build_system.gd para el fantasma/resaltado de demolición: un solo nodo
## roaming es más simple que darle un InteractPrompt propio a cada parcela
## cuando solo se puede estar mirando una a la vez.
var crop_prompt: Node3D

func _ready() -> void:
	camera = get_node("Player/Head/Camera3D")
	SaveManager.load_game()
	_restore_plots_visuals()

	crop_prompt = InteractionPrompt3D.instantiate()
	add_child(crop_prompt)
	crop_prompt.hide_prompt()

## Reconecta los visuales de las parcelas cargadas por el guardado (el build
## system recrea los nodos, pero el estado de cultivo vive en metadata).
func _restore_plots_visuals() -> void:
	for piece in get_tree().get_nodes_in_group("build_piece"):
		if piece.has_meta("piece_category") and piece.get_meta("piece_category", "") == "garden":
			var state: String = piece.get_meta("crop_state", "empty")
			var progress: float = float(piece.get_meta("crop_progress", 0.0))
			var watered_until: float = float(piece.get_meta("watered_until", 0.0))
			CropManager.restore_plot(piece, state, progress, watered_until)

func _process(_delta: float) -> void:
	_update_crop_prompt()

## Prompt de interacción para la parcela apuntada, con la misma imagen real
## de tecla que usan cama/escritorio (interaction_prompt_3d.tscn). Cosechar
## usa la tecla "interact" (E, igual que el resto); sembrar/regar son de
## herramienta (click izquierdo), que no tiene una acción con nombre en
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

## El prompt de huerta no se muestra con una pantalla modal abierta, ni
## mientras hay una pieza de construcción equipada (ese click/esa mirada ya
## son del sistema de construcción — estado de gameplay, no una pantalla, por
## eso se consulta aparte de UIState).
func _crop_prompt_blocked() -> bool:
	if UIState.is_any_modal_open():
		return true
	var build_system := get_tree().get_first_node_in_group("build_system")
	return build_system != null and build_system.equipped_category != "none"

func _unhandled_input(event: InputEvent) -> void:
	if UIState.is_any_modal_open():
		return
	if event.is_action_pressed("interact"):
		_handle_interact()
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_handle_tool_use_click()

## Tecla E: interactuar/agarrar. No depende de la herramienta equipada — sirve
## para interactuables genéricos (registrados en InteractionManager) y para
## cosechar un cultivo listo. Plantar/regar es acción de herramienta y va por
## click izquierdo (_handle_tool_use_click), no acá.
func _handle_interact() -> void:
	var target: Node = InteractionManager.get_from_ray(camera, 4.0)
	if target and target.has_method("interact"):
		var player := get_tree().get_first_node_in_group("player")
		var tool_id: String = player.current_tool_id if player else ""
		target.interact(tool_id, player)
		return

	var result := _cast_crop_ray()
	if result.is_empty():
		return
	var collider: Object = result.get("collider")
	if collider is Node and collider.has_meta("piece_category") and collider.get_meta("piece_category", "") == "garden":
		DevMode.debug_log("crop", "cosechar %s" % collider.name)
		CropManager.harvest_plot(collider, Hotbar)

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
		DevMode.debug_log("needs", "comió %s, hambre=%.0f" % [equipped_id, PlayerNeeds.hunger])
		return

	var result := _cast_crop_ray()
	if result.is_empty():
		return
	var collider: Object = result.get("collider")
	if collider and collider is Node and collider.has_meta("piece_category") and collider.get_meta("piece_category", "") == "garden":
		var player := get_tree().get_first_node_in_group("player")
		var tool_id: String = player.current_tool_id if player else ""
		DevMode.debug_log("crop", "click en %s con tool=%s" % [collider.name, tool_id])
		CropManager.use_tool(collider, tool_id, Hotbar)

func _cast_crop_ray() -> Dictionary:
	var space_state := get_world_3d().direct_space_state
	var origin: Vector3 = camera.global_position
	var target: Vector3 = origin + camera.global_transform.basis * Vector3(0, 0, -4.0)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [get_tree().get_first_node_in_group("player").get_rid()]
	# las parcelas son StaticBody3D, pero se dejan pasar Area3D por si algún
	# interactuable futuro las usa
	query.collide_with_areas = true
	query.collide_with_bodies = true
	return space_state.intersect_ray(query)
