extends Node

@export var plot_id: String = ""

func _ready() -> void:
    add_to_group("plantable")
    if has_meta("piece_category") and get_meta("piece_category", "") == "garden":
        # register with CropManager and InteractionManager if present
        if Engine.has_singleton("CropManager"):
            CropManager.register_plantable(self)
        if Engine.has_singleton("InteractionManager"):
            InteractionManager.register_interactable(self)

func interact(tool_id: String, actor: Node) -> void:
    # actor is typically the player; delegate to CropManager for planting
    if Engine.has_singleton("CropManager"):
        CropManager.interact(self, tool_id, Inventory)
    else:
        # fallback: simple local behavior
        if tool_id == "seed":
            self.set_meta("crop_state", "growing")
            self.set_meta("crop_started_at", Time.get_ticks_msec() / 1000.0)
            Inventory.remove_item(Inventory.selected_slot)
