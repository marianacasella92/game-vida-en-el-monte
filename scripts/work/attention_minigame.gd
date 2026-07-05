extends Control

## Mini-juego "Malabares de atención" (GDD, sección 4.6). Orquesta la
## sesión: cuenta regresiva, eventos random de "distracción" sobre un
## alumno al azar, y el resultado final (promedio de atención -> plata).
## WorkSystem llama a start_session()/reset() al entrar/salir del estado
## "trabajando".

signal session_ended(average: float, money_awarded: int)

@export var session_duration: float = 50.0
@export var good_class_threshold: float = 70.0
@export var distraction_multiplier: float = 3.0
@export var distraction_duration: float = 4.0
@export var distraction_interval_min: float = 8.0
@export var distraction_interval_max: float = 14.0

@onready var gameplay: Control = $Gameplay
@onready var timer_label: Label = $Gameplay/TimerLabel
@onready var students: Array = [
	$Gameplay/Students/Student1,
	$Gameplay/Students/Student2,
	$Gameplay/Students/Student3,
]
@onready var results_overlay: Control = $ResultsOverlay
@onready var result_label: Label = $ResultsOverlay/ResultLabel

var _running: bool = false
var _time_left: float = 0.0
var _next_distraction_in: float = 0.0

func start_session() -> void:
	_running = true
	_time_left = session_duration
	_schedule_next_distraction()

	for student in students:
		student.reset()

	timer_label.text = str(int(ceil(session_duration)))
	results_overlay.visible = false
	gameplay.visible = true

func reset() -> void:
	_running = false
	results_overlay.visible = false

func _process(delta: float) -> void:
	if not _running:
		return

	_time_left -= delta
	timer_label.text = str(int(ceil(max(_time_left, 0.0))))

	_next_distraction_in -= delta
	if _next_distraction_in <= 0.0:
		_trigger_distraction_event()
		_schedule_next_distraction()

	if _time_left <= 0.0:
		_end_session()

func _schedule_next_distraction() -> void:
	_next_distraction_in = randf_range(distraction_interval_min, distraction_interval_max)

func _trigger_distraction_event() -> void:
	var active_students: Array = students.filter(func(s): return not s.is_disconnected)
	if active_students.is_empty():
		return
	var chosen = active_students[randi() % active_students.size()]
	chosen.apply_distraction(distraction_multiplier, distraction_duration)

func _end_session() -> void:
	_running = false

	var active_students: Array = students.filter(func(s): return not s.is_disconnected)
	var average: float = 0.0
	if not active_students.is_empty():
		var total: float = 0.0
		for student in active_students:
			total += student.attention
		average = total / active_students.size()

	var good_class: bool = average >= good_class_threshold
	var money_awarded: int = 100 if good_class else int(round(average))

	var headline := "¡Buena clase!" if good_class else "Clase floja."
	result_label.text = "%s Ganaste $%d\n(Esc para volver)" % [headline, money_awarded]

	gameplay.visible = false
	results_overlay.visible = true

	session_ended.emit(average, money_awarded)
