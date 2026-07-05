extends Node

## Necesidades personales de la jugadora (GDD 4.8). El debuff de movimiento y
## la "vida"/muerte que describe el GDD para cuando se descuidan hambre/sueño
## todavía no están implementados — quedan para cuando se cierre este sprint.

signal hunger_changed(value: float)
signal sleep_changed(value: float)

@export var max_hunger: float = 100.0
## Valor de prueba para poder testear rápido (se vacía del todo en ~2 minutos
## reales) — ajustar cuando se sienta jugado, mismo criterio que crop_growth_time.
@export var hunger_decay_per_second: float = 100.0 / 120.0

@export var max_sleep: float = 100.0
## Igual que hunger_decay_per_second: valor de prueba (~3 minutos reales en
## reposo). GDD 4.8: baja "con las horas despierta y con el esfuerzo de las
## tareas" — el esfuerzo se modela con sleep_decay_multiplier_active mientras
## se corre o se trabaja (ver _is_exerting()).
@export var sleep_decay_per_second: float = 100.0 / 180.0
@export var sleep_decay_multiplier_active: float = 2.5

## item_id -> cuánta hambre recupera. Mismo patrón data-driven que CATALOG/ITEMS/
## GROWTH_STAGE_SCENES: agregar un alimento nuevo (lechuga, tomate, lo que sea
## de los packs de farm ya disponibles) es sumar una entrada acá, no una rama
## de if/elif nueva.
const FOOD_ITEMS := {
	"carrot": 35.0,
}

var hunger: float
var sleep: float

func _ready() -> void:
	add_to_group("player_needs")
	hunger = max_hunger
	sleep = max_sleep

func _process(delta: float) -> void:
	if hunger > 0.0:
		hunger = clampf(hunger - hunger_decay_per_second * delta, 0.0, max_hunger)
		hunger_changed.emit(hunger)

	if sleep > 0.0:
		var rate: float = sleep_decay_per_second
		if _is_exerting():
			rate *= sleep_decay_multiplier_active
		sleep = clampf(sleep - rate * delta, 0.0, max_sleep)
		sleep_changed.emit(sleep)

## GDD 4.8: el sueño baja más rápido con "el esfuerzo de las tareas (trabajar,
## cultivar, construir)". Correr y trabajar son estados sostenidos, fáciles de
## chequear cada frame; plantar/regar/construir son acciones puntuales (un
## click), no estados — si más adelante hace falta que también pesen, se les
## suma un costo de sueño fijo en su propia acción, no acá.
func _is_exerting() -> bool:
	if Input.is_action_pressed("sprint"):
		return true
	var work_system: Node = get_tree().get_first_node_in_group("work_system")
	if work_system and "is_working" in work_system and work_system.is_working:
		return true
	return false

## Intenta comer item_id. Devuelve true si era comida (y hay que sacarlo del
## inventario), false si no hacía nada (para que quien llama sepa si tiene que
## consumir el ítem o no).
func try_eat(item_id: String) -> bool:
	if not FOOD_ITEMS.has(item_id):
		return false
	hunger = clampf(hunger + FOOD_ITEMS[item_id], 0.0, max_hunger)
	hunger_changed.emit(hunger)
	return true

## Dormir restaura todo de una, por ahora (sin ciclo día/noche todavía que le
## dé sentido a una recuperación gradual/nocturna — Sprint 4.4).
func sleep_now() -> void:
	sleep = max_sleep
	sleep_changed.emit(sleep)

func get_save_data() -> Dictionary:
	return {"hunger": hunger, "sleep": sleep}

func apply_save_data(data: Dictionary) -> void:
	hunger = data.get("hunger", max_hunger)
	sleep = data.get("sleep", max_sleep)
	hunger_changed.emit(hunger)
	sleep_changed.emit(sleep)
