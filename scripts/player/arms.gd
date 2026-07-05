extends Node3D

@export var hand_mesh_color: Color = Color(0.95, 0.8, 0.7)
@export var item_mesh_color: Color = Color(0.6, 0.9, 0.6)
@export var real_arms_scene: PackedScene = preload("res://assets/character/first_person_hands_rigged.glb")

var arms_root: Node3D
var placeholder_root: Node3D
var real_model_root: Node3D
var left_arm: MeshInstance3D
var right_arm: MeshInstance3D
var held_item: MeshInstance3D
var real_model: Node3D

func _ready() -> void:
	arms_root = Node3D.new()
	arms_root.name = "ArmsRoot"
	arms_root.position = Vector3(0.08, -0.18, -0.28)
	add_child(arms_root)

	placeholder_root = Node3D.new()
	placeholder_root.name = "PlaceholderRoot"
	arms_root.add_child(placeholder_root)

	# simple placeholder geometry for left and right forearms
	left_arm = MeshInstance3D.new()
	left_arm.mesh = CapsuleMesh.new()
	left_arm.scale = Vector3(0.08, 0.3, 0.08)
	left_arm.position = Vector3(-0.15, -0.18, -0.25)
	placeholder_root.add_child(left_arm)

	right_arm = MeshInstance3D.new()
	right_arm.mesh = CapsuleMesh.new()
	right_arm.scale = Vector3(0.08, 0.3, 0.08)
	right_arm.position = Vector3(0.15, -0.18, -0.25)
	placeholder_root.add_child(right_arm)

	# placeholder held item
	held_item = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.12, 0.12, 0.12)
	held_item.mesh = box
	held_item.position = Vector3(0.18, -0.2, -0.4)
	placeholder_root.add_child(held_item)

	real_model_root = Node3D.new()
	real_model_root.name = "RealModelRoot"
	arms_root.add_child(real_model_root)

	_apply_materials()

	if real_arms_scene:
		real_model = real_arms_scene.instantiate()
		real_model.name = "RealArmsModel"
		real_model_root.add_child(real_model)
		placeholder_root.visible = false

	# start hidden; will be shown when inventory selects an item
	visible = false

func _apply_materials() -> void:
	var mat1 := StandardMaterial3D.new()
	mat1.albedo_color = hand_mesh_color
	left_arm.material_override = mat1
	right_arm.material_override = mat1

	var mat2 := StandardMaterial3D.new()
	mat2.albedo_color = item_mesh_color
	held_item.material_override = mat2

func show_arms(visible_state: bool) -> void:
	visible = visible_state

func update_from_inventory() -> void:
	var sel: Dictionary = Inventory.get_selected_item()
	if sel.is_empty():
		show_arms(false)
		return
	# show arms when there is a selected item
	show_arms(true)
	if real_model_root and real_model_root.get_child_count() > 0:
		real_model_root.visible = true
		placeholder_root.visible = false
	else:
		real_model_root.visible = false
		placeholder_root.visible = true

	# optionally change placeholder held_item color based on item id when using placeholder
	if placeholder_root.visible:
		var id: String = sel.get("id", "")
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
