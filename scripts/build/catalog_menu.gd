extends Control

## Panel de catálogo: lista de categorías a la izquierda, lista de variantes
## (con scroll) a la derecha. Reemplaza al menú radial para poder escalar a
## categorías con muchas piezas sin que se vuelva imposible de usar con mouse.

signal piece_chosen(category: String, variant: String)
signal cancelled

const PANEL_SIZE := Vector2(560, 420)

var categories: Array = []
var category_labels: Dictionary = {}
var category_variants: Dictionary = {} # category_id -> {variant_id: label}
var active_category: String = ""

var category_list: VBoxContainer
var variant_list: VBoxContainer

func _ready() -> void:
	visible = false
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -PANEL_SIZE / 2.0
	panel.custom_minimum_size = PANEL_SIZE
	add_child(panel)

	var hbox := HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	panel.add_child(hbox)

	var category_scroll := ScrollContainer.new()
	category_scroll.custom_minimum_size = Vector2(180, PANEL_SIZE.y - 24)
	hbox.add_child(category_scroll)
	category_list = VBoxContainer.new()
	category_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	category_scroll.add_child(category_list)

	var variant_scroll := ScrollContainer.new()
	variant_scroll.custom_minimum_size = Vector2(340, PANEL_SIZE.y - 24)
	hbox.add_child(variant_scroll)
	variant_list = VBoxContainer.new()
	variant_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	variant_scroll.add_child(variant_list)

## catalog: category_id -> {"label": String, "variants": {variant_id: label}}
## Se le agrega automáticamente la opción "none" (manos vacías).
func setup(catalog: Dictionary) -> void:
	categories = catalog.keys()
	category_labels = {}
	category_variants = {}
	for category_id in catalog:
		category_labels[category_id] = catalog[category_id]["label"]
		category_variants[category_id] = catalog[category_id]["variants"]
	categories.append("none")
	category_labels["none"] = "Manos vacías"
	category_variants["none"] = {}

func open() -> void:
	active_category = ""
	_rebuild_categories()
	_clear_variants()
	visible = true

func close() -> void:
	visible = false

func _clear_variants() -> void:
	for child in variant_list.get_children():
		child.queue_free()

func _rebuild_categories() -> void:
	for child in category_list.get_children():
		child.queue_free()
	for category_id in categories:
		var button := Button.new()
		button.text = category_labels[category_id]
		button.toggle_mode = true
		button.button_pressed = category_id == active_category
		button.pressed.connect(_on_category_pressed.bind(category_id))
		category_list.add_child(button)

func _on_category_pressed(category_id: String) -> void:
	var variants: Dictionary = category_variants.get(category_id, {})
	if variants.size() <= 1:
		var variant_id: String = variants.keys()[0] if variants.size() > 0 else ""
		piece_chosen.emit(category_id, variant_id)
		return

	active_category = category_id
	_rebuild_categories()
	_rebuild_variants(category_id)

func _rebuild_variants(category_id: String) -> void:
	_clear_variants()
	var variants: Dictionary = category_variants[category_id]
	for variant_id in variants:
		var button := Button.new()
		button.text = variants[variant_id]
		button.pressed.connect(_on_variant_pressed.bind(category_id, variant_id))
		variant_list.add_child(button)

func _on_variant_pressed(category_id: String, variant_id: String) -> void:
	piece_chosen.emit(category_id, variant_id)

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		cancelled.emit()

func _unhandled_input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("close_window"):
		cancelled.emit()
