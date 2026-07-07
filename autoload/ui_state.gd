extends Node

## Fuente única de verdad de "qué pantalla modal está abierta" — el patrón
## "máquina de estados de juego" que usan los estudios (jugando / en menú /
## pausado), en su versión mínima. Antes había ~10 lugares con la misma
## cadena `work_system.is_working or phone_system.is_open or ...`: cada
## pantalla nueva obligaba a tocar todos, y olvidarse de uno ya causó bugs
## reales (Esc abriendo pausa encima de otra pantalla). Ahora cada pantalla
## se registra al abrir/cerrar y todo el mundo pregunta acá.
##
## Qué cuenta como "modal": una pantalla que toma el control del input
## (celular, mochila, catálogo de construcción, sesión de trabajo, pausa).
## Qué NO cuenta: estados de gameplay como "pieza de construcción equipada"
## (build_system.equipped_category) — eso bloquea otras cosas, pero es parte
## del juego, no una pantalla; se consulta directo donde hace falta.
##
## open()/close() son idempotentes: cerrar algo que no está abierto no es un
## error (pasa legítimamente, ej. _exit_build_mode cierra el catálogo esté
## abierto o no).

signal modal_changed()

var _open_modals: Dictionary = {}

func open(id: StringName) -> void:
	_open_modals[id] = true
	modal_changed.emit()

func close(id: StringName) -> void:
	if _open_modals.erase(id):
		modal_changed.emit()

func is_open(id: StringName) -> bool:
	return _open_modals.has(id)

func is_any_modal_open() -> bool:
	return not _open_modals.is_empty()

## Para el toggle de una pantalla desde su propia tecla: "¿hay OTRA pantalla
## abierta que no sea yo?" — si la única abierta es ella misma, puede cerrarse.
func is_any_modal_open_except(id: StringName) -> bool:
	return _open_modals.size() > (1 if _open_modals.has(id) else 0)
