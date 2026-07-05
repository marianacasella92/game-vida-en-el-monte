class_name InventorySlot
extends Control

## Un slot de la mochila o del hotbar, con drag & drop nativo de Godot para
## mover/reordenar ítems entre los dos — mismo mecanismo que ya usa
## scripts/work/drag_icon.gd (_get_drag_data/_can_drop_data/_drop_data).

enum Store { BACKPACK, HOTBAR }

var store: Store
var slot_index: int
var has_item: bool = false
var screen: Control  # inventory_screen.gd, seteado por quien crea el slot

func _get_drag_data(_at_position: Vector2) -> Variant:
	if not has_item:
		return null
	var preview := Label.new()
	preview.text = "..."
	set_drag_preview(preview)
	return {"store": store, "slot_index": slot_index}

func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	return typeof(data) == TYPE_DICTIONARY and data.has("store") and data.has("slot_index")

func _drop_data(_at_position: Vector2, data: Variant) -> void:
	screen.move_item(data["store"], data["slot_index"], store, slot_index)
