extends Node3D

## Visuales del ciclo día/noche (Sprint 4.4), referencia estética Green Hell:
## el sol recorre el cielo y se pone, el atardecer tiñe el horizonte, de
## noche sale la luna (disco real en el cielo: ProceduralSkyMaterial dibuja
## un disco por cada DirectionalLight según su angular_distance) y todo
## oscurece. Este nodo es SOLO presentación — la hora vive en TimeManager;
## acá no hay estado propio ni nada que guardar.
##
## Los colores/horas de SKY_KEYFRAMES son estimaciones para validar en el
## editor por la usuaria (regla del proyecto) — se ajustan tocando la tabla,
## sin tocar la lógica.

@onready var sun: DirectionalLight3D = get_node("../SunLight")
@onready var moon: DirectionalLight3D = get_node("../MoonLight")
@onready var environment: Environment = get_node("../WorldEnvironment").environment

const SUNRISE := 6.0
const SUNSET := 20.0

## Puntos clave del cielo a lo largo del día; entre uno y el siguiente se
## interpola linealmente. El de 24.0 repite el de 0.0 para cerrar el ciclo.
## "sun_energy" es la fuerza del sol (0 = bajo el horizonte), "ambient" la
## luz ambiente del Environment (0.6 es el valor diurno ya calibrado).
const SKY_KEYFRAMES := [
	{"hour": 0.0,  "top": Color("0b1026"), "horizon": Color("1a2340"), "sun_energy": 0.0,  "ambient": 0.12},
	{"hour": 5.0,  "top": Color("0b1026"), "horizon": Color("232c4e"), "sun_energy": 0.0,  "ambient": 0.12},
	{"hour": 6.5,  "top": Color("39588c"), "horizon": Color("ff9e5e"), "sun_energy": 0.45, "ambient": 0.3},
	{"hour": 9.0,  "top": Color("3d71b8"), "horizon": Color("bad5ee"), "sun_energy": 0.9,  "ambient": 0.6},
	{"hour": 16.0, "top": Color("3d71b8"), "horizon": Color("bad5ee"), "sun_energy": 0.9,  "ambient": 0.6},
	{"hour": 19.0, "top": Color("2e4a7a"), "horizon": Color("ff7a3d"), "sun_energy": 0.4,  "ambient": 0.28},
	{"hour": 20.5, "top": Color("14203c"), "horizon": Color("452b52"), "sun_energy": 0.0,  "ambient": 0.15},
	{"hour": 24.0, "top": Color("0b1026"), "horizon": Color("1a2340"), "sun_energy": 0.0,  "ambient": 0.12},
]

var _sky: ProceduralSkyMaterial

func _ready() -> void:
	_sky = environment.sky.sky_material
	# tamaño angular del disco en el cielo: sol ~0.5° (como el real), luna igual
	sun.light_angular_distance = 0.53
	moon.light_angular_distance = 0.5

func _process(_delta: float) -> void:
	var hour: float = TimeManager.hour
	_update_lights(hour)
	_update_sky(hour)

## El sol recorre el cielo de este a oeste entre SUNRISE y SUNSET; la luna
## hace el mismo recorrido durante la noche. Solo uno de los dos está activo
## a la vez (dos DirectionalLight con sombra al mismo tiempo costarían de
## más en el renderer Compatibility, y de día la luna no aporta).
func _update_lights(hour: float) -> void:
	var is_day: bool = hour >= SUNRISE and hour < SUNSET
	sun.visible = is_day
	moon.visible = not is_day

	if is_day:
		var t: float = (hour - SUNRISE) / (SUNSET - SUNRISE)
		sun.rotation_degrees = Vector3(-180.0 * t, -30.0, 0.0)
	else:
		# la noche envuelve la medianoche: 20:00 -> 24:00 -> 06:00
		var night_hour: float = hour - SUNSET if hour >= SUNSET else hour + (24.0 - SUNSET)
		var night_length: float = (24.0 - SUNSET) + SUNRISE
		var t: float = night_hour / night_length
		moon.rotation_degrees = Vector3(-180.0 * t, -30.0, 0.0)

func _update_sky(hour: float) -> void:
	var from: Dictionary = SKY_KEYFRAMES[0]
	var to: Dictionary = SKY_KEYFRAMES[SKY_KEYFRAMES.size() - 1]
	for keyframe in SKY_KEYFRAMES:
		if keyframe["hour"] <= hour:
			from = keyframe
		else:
			to = keyframe
			break

	var t: float = 0.0
	if to["hour"] > from["hour"]:
		t = (hour - from["hour"]) / (to["hour"] - from["hour"])

	_sky.sky_top_color = from["top"].lerp(to["top"], t)
	_sky.sky_horizon_color = from["horizon"].lerp(to["horizon"], t)
	# el suelo del cielo acompaña al horizonte para que el empalme no se note
	_sky.ground_horizon_color = _sky.sky_horizon_color
	sun.light_energy = lerpf(from["sun_energy"], to["sun_energy"], t)
	environment.ambient_light_energy = lerpf(from["ambient"], to["ambient"], t)
