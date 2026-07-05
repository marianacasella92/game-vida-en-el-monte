extends Node

var interactables: Array = []

func _ready() -> void:
	add_to_group("interaction_manager")

func register_interactable(node: Node) -> void:
	if not interactables.has(node):
		interactables.append(node)
		node.add_to_group("interactable")

func unregister_interactable(node: Node) -> void:
	interactables.erase(node)
	if node.is_in_group("interactable"):
		node.remove_from_group("interactable")

func get_from_ray(camera: Camera3D, max_distance: float = 4.0) -> Node:
	var space_state := camera.get_world_3d().direct_space_state
	var origin: Vector3 = camera.global_position
	var target: Vector3 = origin + camera.global_transform.basis * Vector3(0, 0, -max_distance)
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	# exclude the player if registered
	var player := get_tree().get_first_node_in_group("player")
	if player:
		query.exclude = [player.get_rid()]
	query.collide_with_areas = true
	query.collide_with_bodies = true
	var result := space_state.intersect_ray(query)
	if result.is_empty():
		return null
	var collider: Object = result.get("collider")
	if collider is Node:
		# climb up to find a registered interactable or node with `interact` method
		var current: Node = collider
		while current:
			if interactables.has(current):
				return current
			if current.has_method("interact"):
				return current
			if not current.get_parent() or not (current.get_parent() is Node):
				break
			current = current.get_parent()
	return null

func get_nearby(player: Node3D, radius: float = 2.2) -> Node:
	var nearest: Node = null
	var best_dist := radius
	for node in interactables:
		if not is_instance_valid(node):
			continue
		var d: float = (node as Node3D).global_position.distance_to(player.global_position)
		if d <= best_dist:
			best_dist = d
			nearest = node
	return nearest
