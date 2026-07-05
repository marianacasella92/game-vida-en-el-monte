extends Label

func _ready() -> void:
	_update_text(Economy.money)
	Economy.money_changed.connect(_update_text)
	Inventory.inventory_changed.connect(_update_text)

func _update_text(_new_amount: int = 0) -> void:
	var item: Dictionary = Inventory.get_selected_item()
	var item_name: String = item.get("name", "Vacío")
	text = "$ %d | Mano: %s" % [Economy.money, item_name]
