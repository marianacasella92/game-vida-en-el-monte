extends Control

## Panel del celular: marketplace con ítems placeholder + botón de guardado
## manual (Milestone 3). Construido por código en _ready(), mismo estilo que
## catalog_menu.gd, en vez de armar el layout a mano en el editor.

const PANEL_SIZE := Vector2(480, 420)

## item_id -> {"label": String, "price": int, "description": String}
## "crate" es el único ítem conectado al sistema de construcción por ahora:
## comprarlo desbloquea la variante "decor"/"crate" en el CATALOG de
## build_system.gd (ver "requires_item" ahí). El resto sigue siendo
## placeholder, sin conexión todavía.
const ITEMS := {
	"seeds": {"label": "Semillas", "price": 20, "description": "Para empezar a cultivar más adelante."},
	"tool": {"label": "Herramienta", "price": 35, "description": "Herramienta genérica de trabajo rural."},
	"decor": {"label": "Adorno", "price": 15, "description": "Decoración simple para la casa."},
	"crate": {"label": "Cajón de madera", "price": 25, "description": "Desbloquea el cajón de madera en el catálogo de construcción (tecla G)."},
}

var money_label: Label
var item_list: VBoxContainer
var save_feedback: Label

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

func refresh() -> void:
	money_label.text = "Plata: $ %d" % Economy.money
	save_feedback.text = ""

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
		if Economy.purchased_items.has(item_id):
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

func _on_save_pressed() -> void:
	SaveManager.save_game()
	save_feedback.text = "Guardado ✓"

func _on_dim_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		get_tree().get_first_node_in_group("phone_system").close_phone()
