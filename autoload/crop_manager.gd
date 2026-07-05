extends Node

signal planted(plot)
signal harvested(plot)
signal state_changed(plot, state)

@export var crop_growth_time: float = 8.0

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
        set_plot_state(plot, "growing", Time.get_ticks_msec() / 1000.0)
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

func _process(delta: float) -> void:
    var now := Time.get_ticks_msec() / 1000.0
    for plot in plantables.duplicate():
        if not is_instance_valid(plot):
            plantables.erase(plot)
            continue
        var state: String = plot.get_meta("crop_state", "empty")
        if state == "growing":
            var started: float = float(plot.get_meta("crop_started_at", 0.0))
            if now - started >= crop_growth_time:
                set_plot_state(plot, "ready", started)
                emit_signal("state_changed", plot, "ready")

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
