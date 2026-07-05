extends Label

## El ícono que se arrastra hacia un alumno (student_widget.gd) para subirle
## la atención. El glifo es puramente estético/aleatorio — no hay distintos
## "tipos" de ícono a nivel de mecánica, cualquiera sirve para cualquier
## alumno.

const GLYPHS := ["🖐️", "❤️", "⭐", "💡", "🙋"]

func _ready() -> void:
	_pick_new_glyph()

func _pick_new_glyph() -> void:
	text = GLYPHS[randi() % GLYPHS.size()]

func _get_drag_data(_at_position: Vector2) -> Variant:
	var preview := Label.new()
	preview.text = text
	preview.add_theme_font_size_override("font_size", 40)
	set_drag_preview(preview)
	return {"type": "attention"}

func _notification(what: int) -> void:
	if what == NOTIFICATION_DRAG_END and get_viewport().gui_is_drag_successful():
		_pick_new_glyph()
