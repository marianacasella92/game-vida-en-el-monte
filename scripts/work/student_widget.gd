extends VBoxContainer

## Un "alumno" del mini-juego de malabares de atención: barra que decae sola
## y sube al recibir un drop del ícono de atención (drag_icon.gd). Ver
## attention_minigame.gd, que orquesta la sesión completa.

@export var decay_rate: float = 2.0
@export var boost_amount: float = 30.0
@export var avatar_glyph: String = "🧑‍🎓"

var attention: float = 100.0
var is_disconnected: bool = false

var _distraction_multiplier: float = 1.0
var _distraction_timer: float = 0.0

@onready var avatar_label: Label = $Avatar
@onready var attention_bar: ProgressBar = $AttentionBar

func _ready() -> void:
	avatar_label.text = avatar_glyph
	reset()

func reset() -> void:
	attention = 100.0
	is_disconnected = false
	_distraction_multiplier = 1.0
	_distraction_timer = 0.0
	_update_visual()

func _process(delta: float) -> void:
	if _distraction_timer > 0.0:
		_distraction_timer -= delta
		if _distraction_timer <= 0.0:
			_distraction_multiplier = 1.0

	if attention > 0.0:
		attention = max(0.0, attention - decay_rate * _distraction_multiplier * delta)

	is_disconnected = attention <= 0.0
	_update_visual()

func boost() -> void:
	attention = min(100.0, attention + boost_amount)
	is_disconnected = attention <= 0.0
	_update_visual()

func apply_distraction(multiplier: float, duration: float) -> void:
	_distraction_multiplier = multiplier
	_distraction_timer = duration

func _update_visual() -> void:
	attention_bar.value = attention
	modulate = Color(0.55, 0.55, 0.55) if is_disconnected else Color(1, 1, 1)

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.get("type") == "attention"

func _drop_data(_at_position: Vector2, _data: Variant) -> void:
	boost()
