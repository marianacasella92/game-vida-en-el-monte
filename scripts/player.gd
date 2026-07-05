extends CharacterBody3D

@export var speed: float = 5.0
@export var sprint_speed: float = 8.0
@export var jump_velocity: float = 4.5
@export var mouse_sensitivity: float = 0.003
@export var min_pitch_deg: float = -80.0
@export var max_pitch_deg: float = 80.0

@onready var head: Node3D = $Head
@onready var build_system: Node = $BuildSystem
@onready var work_system: Node = $WorkSystem
@onready var phone_system: Node = $PhoneSystem
@onready var arms: Node = $Head/Camera3D/Arms

var current_tool_id: String = ""

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

func _ready() -> void:
	add_to_group("player")
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	Inventory.inventory_changed.connect(_on_inventory_changed)
	_on_inventory_changed()

func _on_inventory_changed() -> void:
	var selected_item: Dictionary = Inventory.get_selected_item()
	current_tool_id = selected_item.get("id", "")
	print("[player] inventory changed selected=", current_tool_id, " slot=", Inventory.selected_slot)
	if arms and arms.has_method("update_from_inventory"):
		arms.update_from_inventory()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not build_system.menu_open and not work_system.is_working and not phone_system.is_open:
		rotate_y(-event.relative.x * mouse_sensitivity)
		head.rotate_x(-event.relative.y * mouse_sensitivity)
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(min_pitch_deg), deg_to_rad(max_pitch_deg))

	if event.is_action_pressed("ui_cancel"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	elif event is InputEventMouseButton and event.pressed and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

	for slot in range(9):
		if event.is_action_pressed("hotbar_%d" % (slot + 1)):
			Inventory.select_slot(slot)
			break

func _physics_process(delta: float) -> void:
	if work_system.is_working or phone_system.is_open:
		return

	if not is_on_floor():
		velocity.y -= gravity * delta

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var move_speed: float = sprint_speed if Input.is_action_pressed("sprint") else speed
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0.0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * move_speed
		velocity.z = direction.z * move_speed
	else:
		velocity.x = move_toward(velocity.x, 0.0, move_speed)
		velocity.z = move_toward(velocity.z, 0.0, move_speed)

	move_and_slide()
