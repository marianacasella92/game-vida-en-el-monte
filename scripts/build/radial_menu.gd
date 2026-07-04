extends Control

const RADIUS := 110.0
const SUB_RADIUS := 70.0
const NODE_RADIUS := 34.0
const SUB_NODE_RADIUS := 26.0
const DEAD_ZONE := 20.0
const SUB_DEAD_ZONE := 14.0
## A partir de qué fracción de RADIUS, con una categoría con variantes ya
## resaltada, se abre el submenú de variantes (no hace falta llegar al tope).
const SUBMENU_THRESHOLD := RADIUS * 0.75

var categories: Array = []
var category_labels: Dictionary = {}
var category_variants: Dictionary = {} # category_id -> {variant_id: label}

var pointer := Vector2.ZERO
var level := 1
var active_category: String = ""
var selected_category: String = ""
var selected_variant: String = ""

func _ready() -> void:
	visible = false

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
	pointer = Vector2.ZERO
	level = 1
	active_category = ""
	selected_category = ""
	selected_variant = ""
	visible = true
	queue_redraw()

## Devuelve {"category": String, "variant": String}, o {} si se soltó en la zona muerta.
func close() -> Dictionary:
	visible = false
	if selected_category == "":
		return {}
	var variant: String = selected_variant
	if variant == "":
		var variants: Dictionary = category_variants.get(selected_category, {})
		if variants.size() > 0:
			variant = variants.keys()[0]
	return {"category": selected_category, "variant": variant}

func add_motion(delta: Vector2) -> void:
	pointer += delta
	var max_radius: float = SUB_RADIUS if level == 2 else RADIUS
	if pointer.length() > max_radius:
		pointer = pointer.normalized() * max_radius
	_update_selection()
	queue_redraw()

func _direction_for_index(index: int, count: int) -> Vector2:
	var angle: float = -PI / 2.0 + TAU * float(index) / float(count)
	return Vector2(cos(angle), sin(angle))

func _closest_by_direction(pointer_dir: Vector2, ids: Array) -> String:
	var best_id := ""
	var best_dot := -INF
	for i in ids.size():
		var dot: float = pointer_dir.dot(_direction_for_index(i, ids.size()))
		if dot > best_dot:
			best_dot = dot
			best_id = ids[i]
	return best_id

## Nivel 1 elige categoría (pared/piso/techo/...); si esa categoría tiene más
## de una variante y el jugador empuja el puntero hasta el borde, se entra al
## nivel 2 para elegir la variante puntual (puerta, ventana, esquina, etc.).
func _update_selection() -> void:
	if level == 1:
		selected_variant = ""
		if pointer.length() < DEAD_ZONE:
			selected_category = ""
			return
		selected_category = _closest_by_direction(pointer.normalized(), categories)

		var variants: Dictionary = category_variants.get(selected_category, {})
		if variants.size() > 1 and pointer.length() >= SUBMENU_THRESHOLD:
			level = 2
			active_category = selected_category
			pointer = Vector2.ZERO
	else:
		if pointer.length() < SUB_DEAD_ZONE:
			selected_variant = ""
			return
		var variant_ids: Array = category_variants[active_category].keys()
		selected_variant = _closest_by_direction(pointer.normalized(), variant_ids)

func _draw() -> void:
	var center: Vector2 = size / 2.0
	var font: Font = ThemeDB.fallback_font
	var font_size := 16

	if level == 1:
		for i in categories.size():
			var category_id: String = categories[i]
			var pos: Vector2 = center + _direction_for_index(i, categories.size()) * RADIUS
			var label: String = category_labels[category_id]
			if category_variants[category_id].size() > 1:
				label += " »"
			_draw_node(pos, NODE_RADIUS, label, category_id == selected_category, font, font_size)
	else:
		var variant_ids: Array = category_variants[active_category].keys()
		for i in variant_ids.size():
			var variant_id: String = variant_ids[i]
			var pos: Vector2 = center + _direction_for_index(i, variant_ids.size()) * SUB_RADIUS
			var label: String = category_variants[active_category][variant_id]
			_draw_node(pos, SUB_NODE_RADIUS, label, variant_id == selected_variant, font, font_size)

		var title: String = category_labels[active_category]
		var title_size: Vector2 = font.get_string_size(title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		draw_string(font, center - title_size / 2.0 - Vector2(0, SUB_RADIUS + 20), title, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color(1, 1, 1, 0.7))

	draw_line(center, center + pointer, Color(1, 1, 0, 0.8), 3.0)
	draw_circle(center, 5.0, Color(1, 1, 0, 0.9))

func _draw_node(pos: Vector2, radius: float, label: String, is_selected: bool, font: Font, font_size: int) -> void:
	var color: Color = Color(1, 1, 1, 0.9) if is_selected else Color(0.15, 0.15, 0.15, 0.75)
	draw_circle(pos, radius, color)

	var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var text_color: Color = Color.BLACK if is_selected else Color.WHITE
	var text_pos: Vector2 = pos - text_size / 2.0 + Vector2(0, font_size * 0.35)
	draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)
