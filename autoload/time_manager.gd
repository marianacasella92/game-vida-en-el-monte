extends Node

## Hora y día del mundo (Sprint 4.4). Solo lleva el TIEMPO — los visuales
## (sol/luna/cielo) los maneja day_night.gd en la escena del mundo leyendo
## `hour` cada frame, y cualquier sistema futuro que dependa de la hora
## (trabajar de día, eventos nocturnos) consulta acá o escucha las señales.
##
## La duración del día se lee de config/day_night.cfg (GDD 4.9: editable sin
## tocar código). Persiste día+hora con el contrato estándar de guardado.

signal day_changed(day: int)

const CONFIG_PATH := "res://config/day_night.cfg"

## defaults si falta el archivo de config o alguna clave
var day_length_minutes: float = 12.0
var start_hour: float = 8.0
var wake_hour: float = 7.0

var day: int = 1
var hour: float = 8.0  # 0..24, fracción incluida (7.5 = 07:30)

func _ready() -> void:
	_load_config()
	hour = start_hour

func _load_config() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(CONFIG_PATH) != OK:
		push_warning("[time] no se pudo leer %s — usando defaults" % CONFIG_PATH)
		return
	day_length_minutes = cfg.get_value("day_night", "day_length_minutes", day_length_minutes)
	start_hour = cfg.get_value("day_night", "start_hour", start_hour)
	wake_hour = cfg.get_value("day_night", "wake_hour", wake_hour)

func _process(delta: float) -> void:
	var hours_per_second: float = 24.0 / (day_length_minutes * 60.0)
	advance_hours(delta * hours_per_second)

## Avanza el reloj (lo usa _process y la tecla de debug F5). Envuelve la
## medianoche y emite day_changed al cruzarla.
func advance_hours(amount: float) -> void:
	hour += amount
	while hour >= 24.0:
		hour -= 24.0
		day += 1
		day_changed.emit(day)

func is_night() -> bool:
	return hour < 6.0 or hour >= 20.0

## Dormir: salta a la mañana siguiente (o a la de HOY si te acostaste de
## madrugada, antes de wake_hour — no suma un día que no pasó).
func skip_to_morning() -> void:
	if hour >= wake_hour:
		day += 1
		day_changed.emit(day)
	hour = wake_hour

## Reloj legible para logs/UI ("07:30").
func clock_text() -> String:
	return "%02d:%02d" % [int(hour), int(fmod(hour, 1.0) * 60.0)]

func reset() -> void:
	day = 1
	hour = start_hour

func get_save_data() -> Dictionary:
	return {"day": day, "hour": hour}

func apply_save_data(data: Dictionary) -> void:
	day = int(data.get("day", 1))
	hour = float(data.get("hour", start_hour))
