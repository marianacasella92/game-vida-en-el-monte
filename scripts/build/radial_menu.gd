extends Control

const OPTIONS := ["wall", "floor", "roof", "none"]
const LABELS := {"wall": "Pared", "floor": "Piso", "roof": "Techo", "none": "Manos vacías"}
const DIRECTIONS := {
	"wall": Vector2(0, -1),
	"floor": Vector2(1, 0),
	"roof": Vector2(0, 1),
	"none": Vector2(-1, 0),
}
const RADIUS := 110.0
const NODE_RADIUS := 34.0
const DEAD_ZONE := 20.0

var pointer := Vector2.ZERO
var selected: String = ""

func _ready() -> void:
	visible = false

func open() -> void:
	pointer = Vector2.ZERO
	selected = ""
	visible = true
	queue_redraw()

func close() -> String:
	visible = false
	return selected

func add_motion(delta: Vector2) -> void:
	pointer += delta
	if pointer.length() > RADIUS:
		pointer = pointer.normalized() * RADIUS
	_update_selection()
	queue_redraw()

func _update_selection() -> void:
	if pointer.length() < DEAD_ZONE:
		selected = ""
		return
	var best_option := ""
	var best_dot := -INF
	var pointer_dir := pointer.normalized()
	for option in OPTIONS:
		var dot: float = pointer_dir.dot(DIRECTIONS[option])
		if dot > best_dot:
			best_dot = dot
			best_option = option
	selected = best_option

func _draw() -> void:
	var center: Vector2 = size / 2.0
	var font: Font = ThemeDB.fallback_font
	var font_size := 16

	for option in OPTIONS:
		var pos: Vector2 = center + DIRECTIONS[option] * RADIUS
		var is_selected: bool = option == selected
		var color: Color = Color(1, 1, 1, 0.9) if is_selected else Color(0.15, 0.15, 0.15, 0.75)
		draw_circle(pos, NODE_RADIUS, color)

		var label: String = LABELS[option]
		var text_size: Vector2 = font.get_string_size(label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var text_color: Color = Color.BLACK if is_selected else Color.WHITE
		var text_pos: Vector2 = pos - text_size / 2.0 + Vector2(0, font_size * 0.35)
		draw_string(font, text_pos, label, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, text_color)

	draw_line(center, center + pointer, Color(1, 1, 0, 0.8), 3.0)
	draw_circle(center, 5.0, Color(1, 1, 0, 0.9))
