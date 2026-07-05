extends Node

signal inventory_changed()

const SLOT_COUNT: int = 9
const TOOL_SLOTS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8]

var items: Dictionary = {}
var selected_slot: int = 0

func _ready() -> void:
	items = {
		0: {"id": "seed", "name": "Semilla", "stack": 1},
	}
	inventory_changed.emit()

func add_item(item_id: String, item_name: String, stack: int = 1) -> void:
	for slot in range(SLOT_COUNT):
		if items.has(slot) and items[slot].get("id", "") == item_id:
			items[slot]["stack"] += stack
			inventory_changed.emit()
			return
	if items.size() < SLOT_COUNT:
		for slot in range(SLOT_COUNT):
			if not items.has(slot):
				items[slot] = {"id": item_id, "name": item_name, "stack": stack}
				inventory_changed.emit()
				return

func remove_item(slot: int, amount: int = 1) -> void:
	if not items.has(slot):
		return
	items[slot]["stack"] -= amount
	if items[slot]["stack"] <= 0:
		items.erase(slot)
	inventory_changed.emit()

func select_slot(slot: int) -> void:
	if slot < 0 or slot >= SLOT_COUNT:
		return
	selected_slot = slot
	inventory_changed.emit()

func get_selected_item() -> Dictionary:
	if items.has(selected_slot):
		return items[selected_slot]
	return {}

func has_item(item_id: String) -> bool:
	for slot in items.values():
		if slot.get("id", "") == item_id:
			return true
	return false
