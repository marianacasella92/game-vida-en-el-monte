extends Control

## Panel del celular: marketplace con ítems placeholder + botón de guardado
## manual (Milestone 3). Construido por código en _ready(), mismo estilo que
## catalog_menu.gd, en vez de armar el layout a mano en el editor.

const PANEL_SIZE := Vector2(480, 420)

## item_id -> {"label": String, "price": int, "description": String}
## "crate"/"bed"/"desk" son piezas de construcción físicas: comprarlas las
## suma a la MOCHILA (nunca directo al hotbar, ver "skip_hotbar" abajo) —
## recién cuando la jugadora las arrastra al hotbar y las selecciona a mano,
## build_system.gd entra en modo construcción para esa pieza (ver
## "inventory_item" en su CATALOG), y se gasta 1 del stack al colocarla con
## éxito. Se pueden comprar más de una vez (cada compra suma una unidad más
## al stack). "tool"/"decor" siguen siendo placeholder, sin conexión todavía
## (ojo: este "decor" es un ítem genérico de marketplace, no tiene relación
## con la categoría "decor" del catálogo de construcción).
##
## "skip_hotbar" (opcional, bool): usa Backpack.add_item_no_hotbar() en vez
## de Backpack.add_item(). Bug real (07/07/2026): con add_item() normal
## (que intenta el hotbar primero), comprar una pieza de construcción podía
## caer justo en el slot del hotbar ya seleccionado y entrar en modo
## construcción sola, sin que la jugadora hiciera nada — ver
## autoload/backpack.gd. Toda pieza de construcción nueva que se compre
## desde acá necesita este flag en true.
const ITEMS := {
	"seeds": {"label": "Semilla de Zanahoria", "price": 0, "description": "Para plantar en la huerta.", "grants_item": {"id": "seed", "name": "Semilla de Zanahoria"}},
	"watering_can": {"label": "Regadera", "price": 0, "description": "Para regar los cultivos plantados — riego manual, GDD 4.5.", "grants_item": {"id": "watering_can", "name": "Regadera"}},
	"tool": {"label": "Herramienta", "price": 35, "description": "Herramienta genérica de trabajo rural."},
	"decor": {"label": "Adorno", "price": 15, "description": "Decoración simple para la casa."},
	"crate": {"label": "Cajón de madera", "price": 25, "description": "Se suma a la mochila — arrastralo al hotbar y seleccionalo para entrar en modo construcción y colocarlo.", "grants_item": {"id": "crate", "name": "Cajón de madera"}, "skip_hotbar": true},
	"bed": {"label": "Cama simple", "price": 40, "description": "Se suma a la mochila — arrastrala al hotbar y seleccionala para entrar en modo construcción y colocarla. Dormir restaura el sueño.", "grants_item": {"id": "bed", "name": "Cama simple"}, "skip_hotbar": true},
	"desk": {"label": "Escritorio", "price": 0, "description": "Se suma a la mochila — arrastralo al hotbar y seleccionalo para entrar en modo construcción y colocarlo. Sentarse a trabajar.", "grants_item": {"id": "desk", "name": "Escritorio"}, "skip_hotbar": true},
}

var money_label: Label
var item_list: VBoxContainer
var save_feedback: Label
var reset_button: Button

## Ventana de confirmación del botón de reinicio: el primer click la abre por
## esta cantidad de segundos; si no se confirma con un segundo click a
## tiempo, se vence sola y el próximo click vuelve a pedir confirmación — así
## no queda un "click fantasma" pendiente si volvés al celular mucho después
## por otra razón y tocás sin querer el mismo botón.
const RESET_CONFIRM_WINDOW := 5.0
var _reset_confirm_until: float = 0.0

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.5)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	dim.gui_input.connect(_on_dim_input)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -PANEL_SIZE / 2.0
	panel.custom_minimum_size = PANEL_SIZE
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Marketplace"
	title.add_theme_font_size_override("font_size", 22)
	vbox.add_child(title)

	money_label = Label.new()
	vbox.add_child(money_label)

	var item_scroll := ScrollContainer.new()
	item_scroll.custom_minimum_size = Vector2(PANEL_SIZE.x - 24, 260)
	vbox.add_child(item_scroll)
	item_list = VBoxContainer.new()
	item_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	item_list.add_theme_constant_override("separation", 8)
	item_scroll.add_child(item_list)

	var save_button := Button.new()
	save_button.text = "Guardar partida"
	save_button.pressed.connect(_on_save_pressed)
	vbox.add_child(save_button)

	save_feedback = Label.new()
	vbox.add_child(save_feedback)

	reset_button = Button.new()
	reset_button.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4))
	reset_button.pressed.connect(_on_reset_pressed)
	vbox.add_child(reset_button)

func refresh() -> void:
	money_label.text = "Plata: $ %d" % Economy.money
	save_feedback.text = ""
	_update_reset_button()

	for child in item_list.get_children():
		child.queue_free()

	for item_id in ITEMS:
		var item: Dictionary = ITEMS[item_id]
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 12)

		var info := Label.new()
		info.text = "%s ($%d) — %s" % [item["label"], item["price"], item["description"]]
		info.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		info.custom_minimum_size = Vector2(300, 0)
		info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(info)

		var buy_button := Button.new()
		if item.has("grants_item"):
			# consumible: se puede comprar cuantas veces se quiera
			buy_button.text = "Comprar"
			buy_button.pressed.connect(_on_buy_consumable_pressed.bind(item["price"], item["grants_item"], item.get("skip_hotbar", false)))
		elif Economy.purchased_items.has(item_id):
			buy_button.text = "Comprado"
			buy_button.disabled = true
		else:
			buy_button.text = "Comprar"
			buy_button.pressed.connect(_on_buy_pressed.bind(item_id, item["price"]))
		row.add_child(buy_button)

		item_list.add_child(row)

func _on_buy_pressed(item_id: String, price: int) -> void:
	Economy.purchase_item(item_id, price)
	refresh()

func _on_buy_consumable_pressed(price: int, grants_item: Dictionary, skip_hotbar: bool = false) -> void:
	if not Economy.spend_money(price):
		return
	if skip_hotbar:
		Backpack.add_item_no_hotbar(grants_item["id"], grants_item["name"])
	else:
		Backpack.add_item(grants_item["id"], grants_item["name"])
	refresh()

func _on_save_pressed() -> void:
	SaveManager.save_game()
	save_feedback.text = "Guardado ✓"

func _update_reset_button() -> void:
	var confirming: bool = Time.get_unix_time_from_system() < _reset_confirm_until
	reset_button.text = "¿Seguro? Click para confirmar" if confirming else "Reiniciar partida (borra todo)"

func _on_reset_pressed() -> void:
	if Time.get_unix_time_from_system() < _reset_confirm_until:
		SaveManager.reset_game()
		return
	_reset_confirm_until = Time.get_unix_time_from_system() + RESET_CONFIRM_WINDOW
	_update_reset_button()

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().get_first_node_in_group("phone_system").close_phone()
