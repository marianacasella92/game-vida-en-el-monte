extends Node

## Interruptor global de modo desarrollador: apagado por defecto (juego
## "limpio", sin ningún texto/visual de debug). Se prende a mano con F1
## durante desarrollo para volver a ver instrumentación como el StateLabel
## de CropManager. Cualquier sistema nuevo que necesite un visual de debug
## se subscribe a `toggled` o consulta `DevMode.enabled` directamente, en vez
## de inventar su propio flag.

signal toggled(enabled: bool)

var enabled: bool = false

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_dev_mode"):
		enabled = not enabled
		toggled.emit(enabled)
		print("[dev_mode] %s" % ("ON" if enabled else "OFF"))
