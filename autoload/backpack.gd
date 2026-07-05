extends Node

## Mochila: almacenamiento general del personaje (PXD_Diseno_HUD_UI_v1.md,
## sección 4) — separado del hotbar (autoload/hotbar.gd, accesos rápidos
## 1-9). Mismo patrón de datos que Hotbar (slot int -> {id, name, stack}).

signal backpack_changed()

const SLOT_COUNT: int = 30  # grilla 5x6, sin scroll por ahora

var items: Dictionary = {}

func _ready() -> void:
	add_to_group("backpack")

## Punto de entrada único para "darle un ítem nuevo a la jugadora" (cosechar,
## comprar): intenta el hotbar primero (acceso directo), y si está lleno,
## cae acá. Quien recibe un ítem nuevo debería llamar siempre a este método
## (no a Hotbar.add_item() directo), para que el desborde funcione siempre
## igual sin importar de dónde venga el ítem.
func add_item(item_id: String, item_name: String, stack: int = 1) -> void:
	if Hotbar.add_item(item_id, item_name, stack):
		return

	for slot in range(SLOT_COUNT):
		if items.has(slot) and items[slot].get("id", "") == item_id:
			items[slot]["stack"] += stack
			backpack_changed.emit()
			return
	if items.size() < SLOT_COUNT:
		for slot in range(SLOT_COUNT):
			if not items.has(slot):
				items[slot] = {"id": item_id, "name": item_name, "stack": stack}
				backpack_changed.emit()
				return

## Usados por la pantalla de mochila para mover/reordenar ítems entre
## Backpack y Hotbar por drag & drop, sin que la UI tenga que tocar `items`
## directo.
func get_slot(slot: int) -> Dictionary:
	return items.get(slot, {})

func set_slot(slot: int, item: Dictionary) -> void:
	if item.is_empty():
		items.erase(slot)
	else:
		items[slot] = item
	backpack_changed.emit()

func remove_item(slot: int, amount: int = 1) -> void:
	if not items.has(slot):
		return
	items[slot]["stack"] -= amount
	if items[slot]["stack"] <= 0:
		items.erase(slot)
	backpack_changed.emit()

func reset() -> void:
	items = {}
	backpack_changed.emit()

func get_save_data() -> Dictionary:
	return {"items": items}

## Mismo motivo que Hotbar.apply_save_data(): JSON convierte las claves de
## slot (int) a string, hay que reconstruirlas.
func apply_save_data(data: Dictionary) -> void:
	var raw_items: Dictionary = data.get("items", {})
	items = {}
	for key in raw_items:
		items[int(key)] = raw_items[key]
	backpack_changed.emit()
