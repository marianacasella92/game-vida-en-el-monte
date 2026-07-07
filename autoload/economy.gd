extends Node

## Autoload de economía: plata, ítems comprados y el servicio de compra del
## marketplace. La UI (marketplace_ui.gd, y a futuro la app del celular
## diegético) solo LEE el catálogo y llama a buy() — la lógica de "qué pasa
## al comprar" vive acá, así cualquier pantalla nueva de tienda la reusa sin
## duplicarla (separación simulación/presentación).

signal money_changed(new_amount: int)
signal item_purchased(item_id: String)

## Catálogo de la tienda. item_id -> {"label", "price", "description", y
## opcionales:
##   "grants_item": {id, name} — ítem físico: comprarlo lo suma al
##     inventario y se puede comprar cuantas veces se quiera.
##   "skip_hotbar": true — el ítem entra SOLO a la mochila, nunca directo al
##     hotbar. Obligatorio para piezas de construcción ("crate"/"bed"/"desk"):
##     con add_item() normal, la compra podía caer justo en el slot del
##     hotbar ya seleccionado y activar el modo construcción sola, sin que la
##     jugadora hiciera nada (bug real 07/07/2026, ver backpack.gd).
## Sin "grants_item" es un desbloqueo único (purchased_items, se compra una
## sola vez). "tool"/"decor" siguen siendo placeholder sin conexión (ojo:
## este "decor" es un ítem genérico, no la categoría "decor" del catálogo de
## construcción).
const SHOP_CATALOG := {
	"seeds": {"label": "Semilla de Zanahoria", "price": 0, "description": "Para plantar en la huerta.", "grants_item": {"id": "seed", "name": "Semilla de Zanahoria"}},
	"watering_can": {"label": "Regadera", "price": 0, "description": "Para regar los cultivos plantados — riego manual, GDD 4.5.", "grants_item": {"id": "watering_can", "name": "Regadera"}},
	"tool": {"label": "Herramienta", "price": 35, "description": "Herramienta genérica de trabajo rural."},
	"decor": {"label": "Adorno", "price": 15, "description": "Decoración simple para la casa."},
	"crate": {"label": "Cajón de madera", "price": 25, "description": "Se suma a la mochila — arrastralo al hotbar y seleccionalo para entrar en modo construcción y colocarlo.", "grants_item": {"id": "crate", "name": "Cajón de madera"}, "skip_hotbar": true},
	"bed": {"label": "Cama simple", "price": 40, "description": "Se suma a la mochila — arrastrala al hotbar y seleccionala para entrar en modo construcción y colocarla. Dormir restaura el sueño.", "grants_item": {"id": "bed", "name": "Cama simple"}, "skip_hotbar": true},
	"desk": {"label": "Escritorio", "price": 0, "description": "Se suma a la mochila — arrastralo al hotbar y seleccionalo para entrar en modo construcción y colocarlo. Sentarse a trabajar.", "grants_item": {"id": "desk", "name": "Escritorio"}, "skip_hotbar": true},
}

var money: int = 0
var purchased_items: Dictionary = {}

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)

func spend_money(amount: int) -> bool:
	if amount > money:
		return false
	money -= amount
	money_changed.emit(money)
	return true

## Punto de entrada único de compra: resuelve solo si el ítem es físico
## (grants_item → inventario, repetible) o un desbloqueo único
## (purchased_items). Devuelve false si no alcanza la plata o si un
## desbloqueo ya estaba comprado.
func buy(item_id: String) -> bool:
	var item: Dictionary = SHOP_CATALOG.get(item_id, {})
	if item.is_empty():
		push_error("[economy] buy() con item_id desconocido: %s" % item_id)
		return false

	if item.has("grants_item"):
		if not spend_money(item["price"]):
			return false
		var grants: Dictionary = item["grants_item"]
		if item.get("skip_hotbar", false):
			Backpack.add_item_no_hotbar(grants["id"], grants["name"])
		else:
			Backpack.add_item(grants["id"], grants["name"])
		return true

	return purchase_item(item_id, item["price"])

func purchase_item(item_id: String, price: int) -> bool:
	if purchased_items.has(item_id):
		return false
	if not spend_money(price):
		return false
	purchased_items[item_id] = true
	item_purchased.emit(item_id)
	return true

## Usado por SaveManager.reset_game() para volver a partida nueva.
func reset() -> void:
	money = 0
	purchased_items = {}
	money_changed.emit(money)

func get_save_data() -> Dictionary:
	return {"money": money, "purchased_items": purchased_items}

func apply_save_data(data: Dictionary) -> void:
	money = int(data.get("money", 0))
	purchased_items = data.get("purchased_items", {})
	money_changed.emit(money)
