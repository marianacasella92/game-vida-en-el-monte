extends Node3D

@export var hand_mesh_color: Color = Color(0.95, 0.8, 0.7)
@export var item_mesh_color: Color = Color(0.6, 0.9, 0.6)
# false hasta posar el bind pose de RealArmsModel (manos lejos del pivote, fuera de cámara)
@export var use_real_model: bool = false

@onready var arms_root: Node3D = $ArmsRoot
@onready var placeholder_root: Node3D = $ArmsRoot/PlaceholderRoot
@onready var real_model_root: Node3D = $ArmsRoot/RealModelRoot
@onready var left_arm: MeshInstance3D = $ArmsRoot/PlaceholderRoot/LeftArm
@onready var right_arm: MeshInstance3D = $ArmsRoot/PlaceholderRoot/RightArm
@onready var held_item: MeshInstance3D = $ArmsRoot/PlaceholderRoot/HeldItem
@onready var real_held_item: MeshInstance3D = %RealHeldItem
@onready var watering_can_visual: Node3D = %WateringCanVisual
@onready var real_watering_can_visual: Node3D = %RealWateringCanVisual

func _ready() -> void:
	_apply_materials()
	# arms are always visible; only the held item depends on inventory
	visible = true
	update_from_inventory()

func _apply_materials() -> void:
	var mat1 := StandardMaterial3D.new()
	mat1.albedo_color = hand_mesh_color
	left_arm.material_override = mat1
	right_arm.material_override = mat1

	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = item_mesh_color
	held_item.material_override = mat2
	real_held_item.material_override = mat2

func show_arms(visible_state: bool) -> void:
	visible = visible_state

func update_from_inventory() -> void:
	var sel: Dictionary = Hotbar.get_selected_item()
	var showing_real := use_real_model and real_model_root.get_child_count() > 0
	real_model_root.visible = showing_real
	placeholder_root.visible = not showing_real

	var id: String = sel.get("id", "") if not sel.is_empty() else ""
	var is_watering_can := id == "watering_can"

	# la regadera tiene su propio modelo; el resto de los ítems usa la cajita genérica
	held_item.visible = not showing_real and id != "" and not is_watering_can
	real_held_item.visible = showing_real and id != "" and not is_watering_can
	watering_can_visual.visible = not showing_real and is_watering_can
	real_watering_can_visual.visible = showing_real and is_watering_can

	if held_item.visible or real_held_item.visible:
		var mat: StandardMaterial3D = held_item.material_override
		if id == "seed":
			mat.albedo_color = Color(0.9, 0.7, 0.3)
		else:
			mat.albedo_color = item_mesh_color

func attach_item_scene(item_scene: PackedScene) -> void:
	# replace placeholder held_item with provided scene instance
	if held_item and held_item.is_inside_tree():
		held_item.queue_free()
	var inst := item_scene.instantiate()
	inst.name = "HeldItemScene"
	inst.position = Vector3(0.18, -0.2, -0.4)
	arms_root.add_child(inst)
