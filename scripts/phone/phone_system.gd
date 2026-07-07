extends Node3D

## Celular que la jugadora siempre lleva encima (GDD 4.10): se abre/cierra
## con `open_phone` desde cualquier punto del mundo, sin necesidad de
## acercarse a nada. Registrado en UIState como &"phone" — el bloqueo de
## mouse-look/movimiento/otras pantallas sale de ahí, no de que cada sistema
## nos consulte a mano.

const MODAL_ID := &"phone"

@onready var panel: Control = $PhoneUILayer/Panel

func _ready() -> void:
	add_to_group("phone_system")
	panel.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("open_phone"):
		return
	if UIState.is_any_modal_open_except(MODAL_ID):
		return
	if UIState.is_open(MODAL_ID):
		close_phone()
	else:
		open_phone()

func open_phone() -> void:
	UIState.open(MODAL_ID)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	panel.visible = true
	panel.refresh()

func close_phone() -> void:
	UIState.close(MODAL_ID)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	panel.visible = false

## "close_window" (Q) es la tecla dedicada para cerrar cualquier pantalla
## modal — separada de "ui_cancel" (Esc), que es exclusiva del menú de pausa
## (pause_system.gd), para que cerrar una pantalla y abrir pausa nunca
## compitan por el mismo evento en el mismo frame.
func _process(_delta: float) -> void:
	if UIState.is_open(MODAL_ID) and Input.is_action_just_pressed("close_window"):
		close_phone()
