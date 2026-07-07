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
## Pivote de la luna visible: la foto real (assets/enviroment/moon.png) en un
## billboard lejano que rota con la noche — el truco clásico de los survival.
## La MoonLight queda solo como LUZ (sin disco procedural, se apaga en _ready).
@onready var moon_pivot: Node3D = get_node("../MoonPivot")

const SUNRISE := 6.0
const SUNSET := 20.0

## Puntos clave del cielo a lo largo del día; entre uno y el siguiente se
## interpola linealmente. El de 24.0 repite el de 0.0 para cerrar el ciclo.
## "sun_energy" es la fuerza del sol (0 = bajo el horizonte), "ambient" la
## luz ambiente del Environment (0.6 es el valor diurno ya calibrado).
## "sun_color" es el color de la LUZ del sol (y de su disco/halo en el
## cielo): naranja rojizo al amanecer/atardecer, blanco cálido al mediodía —
## sin esto, el disco quedaba blancuzco/gris contra el cielo naranja de la
## mañana (feedback real de la usuaria, 07/07/2026).
const SKY_KEYFRAMES := [
	{"hour": 0.0,  "top": Color("0b1026"), "horizon": Color("1a2340"), "sun_energy": 0.0,  "ambient": 0.12, "sun_color": Color("ff8c42")},
	{"hour": 5.0,  "top": Color("0b1026"), "horizon": Color("232c4e"), "sun_energy": 0.0,  "ambient": 0.12, "sun_color": Color("ff8c42")},
	{"hour": 6.5,  "top": Color("39588c"), "horizon": Color("ff9e5e"), "sun_energy": 0.45, "ambient": 0.3,  "sun_color": Color("ff9a4d")},
	{"hour": 9.0,  "top": Color("3d71b8"), "horizon": Color("bad5ee"), "sun_energy": 0.9,  "ambient": 0.6,  "sun_color": Color("fff7ea")},
	{"hour": 16.0, "top": Color("3d71b8"), "horizon": Color("bad5ee"), "sun_energy": 0.9,  "ambient": 0.6,  "sun_color": Color("fff3dd")},
	{"hour": 19.0, "top": Color("2e4a7a"), "horizon": Color("ff7a3d"), "sun_energy": 0.4,  "ambient": 0.28, "sun_color": Color("ff7a33")},
	{"hour": 20.5, "top": Color("14203c"), "horizon": Color("452b52"), "sun_energy": 0.0,  "ambient": 0.15, "sun_color": Color("ff7a33")},
	{"hour": 24.0, "top": Color("0b1026"), "horizon": Color("1a2340"), "sun_energy": 0.0,  "ambient": 0.12, "sun_color": Color("ff8c42")},
]

var _sky: ProceduralSkyMaterial

func _ready() -> void:
	_sky = environment.sky.sky_material
	# El sol no es un disco nítido sino un resplandor: núcleo un poco más
	# grande que el real (1.5°) + halo ancho del cielo procedural
	# (sun_angle_max/sun_curve) + Glow del Environment (ver world.tscn).
	# Valores estéticos a validar por la usuaria.
	sun.light_angular_distance = 1.5
	_sky.sun_angle_max = 30.0
	_sky.sun_curve = 0.12
	# la luna visible es el billboard de MoonPivot — el disco procedural de la
	# MoonLight se apaga para no dibujar dos lunas
	moon.light_angular_distance = 0.0

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
	moon_pivot.visible = not is_day

	if is_day:
		var t: float = (hour - SUNRISE) / (SUNSET - SUNRISE)
		sun.rotation_degrees = Vector3(-180.0 * t, -30.0, 0.0)
	else:
		# la noche envuelve la medianoche: 20:00 -> 24:00 -> 06:00
		var night_hour: float = hour - SUNSET if hour >= SUNSET else hour + (24.0 - SUNSET)
		var night_length: float = (24.0 - SUNSET) + SUNRISE
		var t: float = night_hour / night_length
		var night_rotation := Vector3(-180.0 * t, -30.0, 0.0)
		moon.rotation_degrees = night_rotation
		# el billboard de la luna cuelga del pivote en +Z: con la misma
		# rotación que la luz, queda siempre en el punto del cielo desde el
		# que "sale" esa luz — luna y sombras coherentes gratis
		moon_pivot.rotation_degrees = night_rotation

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
	sun.light_color = from["sun_color"].lerp(to["sun_color"], t)
	environment.ambient_light_energy = lerpf(from["ambient"], to["ambient"], t)
