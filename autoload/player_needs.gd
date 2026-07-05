extends Node

## Necesidades personales de la jugadora (GDD 4.8): hambre, sueño y vida.
## Vida es el único sistema del juego con penalización dura (muerte ->
## recargar el último guardado) — decisión explícita del GDD, todo lo demás
## (cultivo, construcción) queda sin "game over".

signal hunger_changed(value: float)
signal sleep_changed(value: float)
signal health_changed(value: float)
signal died()

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

@export var max_health: float = 100.0
## Por debajo de esta fracción de hambre O de sueño, se considera "descuidada"
## — dispara la baja de vida y el debuff de movimiento (GDD 4.8).
@export var neglect_threshold_ratio: float = 0.25
## Valores de prueba: ~4 min para morir de descuido si no se atiende nada,
## regen más lenta (~5 min) cuando hambre y sueño están bien.
@export var health_decay_per_second: float = 100.0 / 240.0
@export var health_regen_per_second: float = 100.0 / 300.0
@export var neglected_speed_multiplier: float = 0.6

## item_id -> cuánta hambre recupera. Mismo patrón data-driven que CATALOG/ITEMS/
## GROWTH_STAGE_SCENES: agregar un alimento nuevo (lechuga, tomate, lo que sea
## de los packs de farm ya disponibles) es sumar una entrada acá, no una rama
## de if/elif nueva.
const FOOD_ITEMS := {
	"carrot": 35.0,
}

var hunger: float
var sleep: float
var health: float
var _is_dead: bool = false

func _ready() -> void:
	add_to_group("player_needs")
	reset()

## Vuelve hambre/sueño/vida al máximo. Usado por _ready() y por SaveManager.reset_game().
func reset() -> void:
	hunger = max_hunger
	sleep = max_sleep
	health = max_health
	_is_dead = false
	hunger_changed.emit(hunger)
	sleep_changed.emit(sleep)
	health_changed.emit(health)

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

	_process_health(delta)

## GDD 4.8: "el personaje se mueve más lento y la vida empieza a bajar de a
## poco" si se descuidan hambre/sueño. Regenera de a poco cuando ninguna de
## las dos está en niveles críticos.
func _process_health(delta: float) -> void:
	if is_neglected():
		health = clampf(health - health_decay_per_second * delta, 0.0, max_health)
	elif health < max_health:
		health = clampf(health + health_regen_per_second * delta, 0.0, max_health)
	else:
		return
	health_changed.emit(health)
	if health <= 0.0 and not _is_dead:
		_is_dead = true
		died.emit()
	elif health > 0.0:
		_is_dead = false

func is_neglected() -> bool:
	return hunger <= max_hunger * neglect_threshold_ratio or sleep <= max_sleep * neglect_threshold_ratio

func get_move_speed_multiplier() -> float:
	return neglected_speed_multiplier if is_neglected() else 1.0

## GDD 4.8: "el esfuerzo de las tareas (trabajar, cultivar, construir)". Correr
## y trabajar son estados sostenidos, fáciles de chequear cada frame;
## plantar/regar/construir son acciones puntuales (un click), no estados — si
## más adelante hace falta que también pesen, se les suma un costo de sueño
## fijo en su propia acción, no acá.
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

## Llamado por SaveManager al recargar tras una muerte: pone un piso mínimo de
## hambre/sueño (no el máximo) y la vida al máximo, para que no se vuelva a
## morir instantáneamente si el último guardado también tenía las necesidades
## bajas — sin esto, cargar y morir de nuevo en loop sería posible.
func grant_death_grace() -> void:
	hunger = maxf(hunger, max_hunger * 0.4)
	sleep = maxf(sleep, max_sleep * 0.4)
	health = max_health
	_is_dead = false
	hunger_changed.emit(hunger)
	sleep_changed.emit(sleep)
	health_changed.emit(health)

func get_save_data() -> Dictionary:
	return {"hunger": hunger, "sleep": sleep, "health": health}

func apply_save_data(data: Dictionary) -> void:
	hunger = data.get("hunger", max_hunger)
	sleep = data.get("sleep", max_sleep)
	health = data.get("health", max_health)
	_is_dead = false
	hunger_changed.emit(hunger)
	sleep_changed.emit(sleep)
	health_changed.emit(health)
