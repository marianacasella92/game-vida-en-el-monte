extends Node

@export var plot_id: String = ""

func _ready() -> void:
    add_to_group("plantable")
    if has_meta("piece_category") and get_meta("piece_category", "") == "garden":
        CropManager.register_plantable(self)
        InteractionManager.register_interactable(self)

func interact(tool_id: String, actor: Node) -> void:
    # actor is typically the player; delegate to CropManager for planting
    CropManager.interact(self, tool_id, Inventory)
