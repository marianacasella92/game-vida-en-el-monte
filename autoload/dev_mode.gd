extends Node

## Interruptor global de modo desarrollador: apagado por defecto (juego
## "limpio", sin ningún texto/visual de debug). Se prende a mano con F1
## durante desarrollo para volver a ver instrumentación como el StateLabel
## de CropManager. Cualquier sistema nuevo que necesite un visual de debug
## se subscribe a `toggled` o consulta `DevMode.enabled` directamente, en vez
## de inventar su propio flag.

signal toggled(enabled: bool)

var enabled: bool = false

## Plata que suma cada F2 con el modo desarrollador activo — para poder
## probar el marketplace (comprar cama/escritorio/cajón) sin tener que jugar
## el loop económico entero cada vez.
const DEBUG_MONEY_AMOUNT := 1000

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_mode"):
		enabled = not enabled
		toggled.emit(enabled)
		print("[dev_mode] %s" % ("ON" if enabled else "OFF"))
	elif event.is_action_pressed("debug_add_money") and enabled:
		Economy.add_money(DEBUG_MONEY_AMOUNT)
		print("[dev_mode] +$%d (plata=%d)" % [DEBUG_MONEY_AMOUNT, Economy.money])
	elif event.is_action_pressed("debug_restore_needs") and enabled:
		# PlayerNeeds.reset() ya deja vida/hambre/energía al máximo — la misma
		# función que usa una partida nueva, no hace falta lógica aparte.
		PlayerNeeds.reset()
		print("[dev_mode] vida/hambre/energía al 100%")
	elif event.is_action_pressed("debug_damage_health") and enabled:
		# para probar rápido el efecto de vida baja (viñeta/corazón/desmayo)
		# sin esperar los minutos reales de descuido de hambre/sueño.
		PlayerNeeds.damage(25.0)
		print("[dev_mode] -25 vida (vida=%.0f)" % PlayerNeeds.health)
