extends "res://scripts/build/proximity_interactable.gd"

## Escritorio: al interactuar, le avisa al WorkSystem del jugador para que
## entre al estado "trabajando" (ver scripts/work/work_system.gd). Proximidad,
## prompt y guardas de pantallas modales viven en proximity_interactable.gd.

func _on_interact() -> void:
	var work_system := get_tree().get_first_node_in_group("work_system")
	if work_system:
		work_system.start_working(self)
