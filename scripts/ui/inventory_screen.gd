extends Control

## Pantalla de mochila (PXD_Diseno_HUD_UI_v1.md, sección 4). Construida por
## código en _ready(), mismo estilo que marketplace_ui.gd/catalog_menu.gd, en
## vez de armar el layout a mano en el editor.
##
## Muestra dos almacenes separados lado a lado: la grilla de mochila
## (Backpack, 5x6) a la izquierda y la lista vertical de hotbar (Hotbar,
## tamaño dinámico, con ícono de tecla 1-9 por fila) a la derecha. Arrastrar
## un ítem entre ambos mueve/intercambia entre Backpack.items y Hotbar.items
## vía move_item().

const FRAME_EMPTY := preload("res://assets/hud/inv_slot_frame_empty.png")
const FRAME_OCCUPIED := preload("res://assets/hud/inv_slot_frame_occupied.png")
const FRAME_SELECTED := preload("res://assets/hud/inv_slot_frame_selected_gold.png")
const TITLE_TEXTURE := preload("res://assets/hud/inv_title_text.png")
const DIVIDER_TOP := preload("res://assets/hud/inv_divider_top.png")
const DIVIDER_BOTTOM := preload("res://assets/hud/inv_divider_bottom.png")
const MONEY_ICON := preload("res://assets/hud/icon_money.png")

const FONT_TITLE := preload("res://assets/hud/fonts/Walter_Turncoat/WalterTurncoat-Regular.ttf")
const FONT_BODY := preload("res://assets/hud/fonts/Syne_Mono/SyneMono-Regular.ttf")
const BLUR_SHADER := preload("res://scenes/ui/background_blur.gdshader")

## Iconos de tecla (assets/hud/keyset/White) para la fila de hotbar — el
## índice del array es el slot (0-8), que corresponde a las teclas 1-9
## (ver player.gd: "hotbar_%d" % (slot + 1)). Blancos para que se lean sobre
## el fondo oscurecido, igual que el resto de los íconos del HUD.
const KEY_ICONS := [
	preload("res://assets/hud/keyset/White/1.png"),
	preload("res://assets/hud/keyset/White/2.png"),
	preload("res://assets/hud/keyset/White/3.png"),
	preload("res://assets/hud/keyset/White/4.png"),
	preload("res://assets/hud/keyset/White/5.png"),
	preload("res://assets/hud/keyset/White/6.png"),
	preload("res://assets/hud/keyset/White/7.png"),
	preload("res://assets/hud/keyset/White/8.png"),
	preload("res://assets/hud/keyset/White/9.png"),
]

const SLOT_SIZE := Vector2(80, 80)
const KEY_ICON_SIZE := Vector2(28, 28)
const GRID_COLUMNS := 5

var money_label: Label
var backpack_grid: GridContainer
var hotbar_list: VBoxContainer
var _backpack_slots: Array[InventorySlot] = []
var _hotbar_slots: Array[InventorySlot] = []

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var bg := ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.45)  # fallback si el shader no compila: oscurecido simple sin blur
	var blur_material := ShaderMaterial.new()
	blur_material.shader = BLUR_SHADER
	bg.material = blur_material
	add_child(bg)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_bottom", 30)
	add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	margin.add_child(vbox)

	var header := HBoxContainer.new()
	vbox.add_child(header)

	var title := TextureRect.new()
	title.texture = TITLE_TEXTURE
	title.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	title.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	title.custom_minimum_size = Vector2(200, 34)
	header.add_child(title)

	var header_spacer := Control.new()
	header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(header_spacer)

	var money_icon := TextureRect.new()
	money_icon.texture = MONEY_ICON
	money_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	money_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	money_icon.custom_minimum_size = Vector2(32, 32)
	header.add_child(money_icon)

	money_label = Label.new()
	money_label.add_theme_font_override("font", FONT_TITLE)
	money_label.add_theme_font_size_override("font_size", 22)
	money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(money_label)

	var divider_top := TextureRect.new()
	divider_top.texture = DIVIDER_TOP
	divider_top.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider_top.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	divider_top.custom_minimum_size = Vector2(0, 11)
	vbox.add_child(divider_top)

	var content_row := HBoxContainer.new()
	content_row.add_theme_constant_override("separation", 32)
	vbox.add_child(content_row)

	var backpack_section := VBoxContainer.new()
	backpack_section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content_row.add_child(backpack_section)

	var backpack_label := Label.new()
	backpack_label.text = "Mochila"
	backpack_label.add_theme_font_override("font", FONT_BODY)
	backpack_section.add_child(backpack_label)

	backpack_grid = GridContainer.new()
	backpack_grid.columns = GRID_COLUMNS
	backpack_grid.add_theme_constant_override("h_separation", 6)
	backpack_grid.add_theme_constant_override("v_separation", 6)
	backpack_section.add_child(backpack_grid)
	for slot in range(Backpack.SLOT_COUNT):
		_backpack_slots.append(_make_slot(InventorySlot.Store.BACKPACK, slot, backpack_grid))

	# Fila de hotbar a la derecha de la mochila, en lista vertical: cada fila
	# muestra el ícono de la tecla (1-9, assets/hud/keyset) junto al slot.
	var hotbar_section := VBoxContainer.new()
	content_row.add_child(hotbar_section)

	var hotbar_label := Label.new()
	hotbar_label.text = "Accesos rápidos"
	hotbar_label.add_theme_font_override("font", FONT_BODY)
	hotbar_section.add_child(hotbar_label)

	hotbar_list = VBoxContainer.new()
	hotbar_list.add_theme_constant_override("separation", 6)
	hotbar_section.add_child(hotbar_list)
	for slot in range(Hotbar.SLOT_COUNT):
		_hotbar_slots.append(_make_hotbar_row(slot, hotbar_list))

	var divider_bottom := TextureRect.new()
	divider_bottom.texture = DIVIDER_BOTTOM
	divider_bottom.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	divider_bottom.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	divider_bottom.custom_minimum_size = Vector2(0, 33)
	vbox.add_child(divider_bottom)

	Economy.money_changed.connect(_on_money_changed)
	Backpack.backpack_changed.connect(refresh)
	Hotbar.inventory_changed.connect(refresh)

func _make_slot(store: InventorySlot.Store, slot_index: int, parent: Container) -> InventorySlot:
	var slot := InventorySlot.new()
	slot.custom_minimum_size = SLOT_SIZE
	slot.focus_mode = Control.FOCUS_ALL
	slot.store = store
	slot.slot_index = slot_index
	slot.screen = self
	parent.add_child(slot)

	var frame := TextureRect.new()
	frame.name = "Frame"
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	frame.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	frame.texture = FRAME_EMPTY
	slot.add_child(frame)

	var item_name := Label.new()
	item_name.name = "ItemName"
	item_name.set_anchors_preset(Control.PRESET_FULL_RECT)
	item_name.add_theme_font_override("font", FONT_BODY)
	item_name.add_theme_font_size_override("font_size", 11)
	item_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_name.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	item_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	slot.add_child(item_name)

	var stack_label := Label.new()
	stack_label.name = "StackLabel"
	stack_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	stack_label.add_theme_font_override("font", FONT_BODY)
	stack_label.add_theme_font_size_override("font_size", 10)
	slot.add_child(stack_label)

	return slot

## Una fila del hotbar: ícono de tecla (1-9) + slot, para la columna derecha
## de la pantalla. slot_index es 0-based; KEY_ICONS ya está indexado igual.
func _make_hotbar_row(slot_index: int, parent: Container) -> InventorySlot:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	parent.add_child(row)

	var key_icon := TextureRect.new()
	key_icon.custom_minimum_size = KEY_ICON_SIZE
	key_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if slot_index < KEY_ICONS.size():
		key_icon.texture = KEY_ICONS[slot_index]
	row.add_child(key_icon)

	return _make_slot(InventorySlot.Store.HOTBAR, slot_index, row)

func refresh() -> void:
	money_label.text = "%d" % Economy.money
	for slot in range(Backpack.SLOT_COUNT):
		_refresh_slot(_backpack_slots[slot], Backpack.get_slot(slot), false)
	for slot in range(Hotbar.SLOT_COUNT):
		_refresh_slot(_hotbar_slots[slot], Hotbar.get_slot(slot), slot == Hotbar.selected_slot)

func _refresh_slot(slot: InventorySlot, item: Dictionary, is_equipped: bool) -> void:
	var frame: TextureRect = slot.get_node("Frame")
	var item_name: Label = slot.get_node("ItemName")
	var stack_label: Label = slot.get_node("StackLabel")

	slot.has_item = not item.is_empty()

	if is_equipped:
		frame.texture = FRAME_SELECTED
	elif slot.has_item:
		frame.texture = FRAME_OCCUPIED
	else:
		frame.texture = FRAME_EMPTY

	if slot.has_item:
		item_name.text = item.get("name", "")
		var stack: int = item.get("stack", 1)
		stack_label.text = str(stack) if stack > 1 else ""
	else:
		item_name.text = ""
		stack_label.text = ""

func _on_money_changed(_new_amount: int) -> void:
	refresh()

## Llamado por inventory_slot.gd al soltar un drag & drop. Si origen y
## destino son el mismo store/slot no hace nada; si no, intercambia el
## contenido de ambos slots (mover a un slot ocupado swapea en vez de perder
## el ítem que ya estaba ahí).
func move_item(from_store: InventorySlot.Store, from_slot: int, to_store: InventorySlot.Store, to_slot: int) -> void:
	if from_store == to_store and from_slot == to_slot:
		return

	var from_container = Backpack if from_store == InventorySlot.Store.BACKPACK else Hotbar
	var to_container = Backpack if to_store == InventorySlot.Store.BACKPACK else Hotbar

	var moving_item: Dictionary = from_container.get_slot(from_slot)
	var target_item: Dictionary = to_container.get_slot(to_slot)

	to_container.set_slot(to_slot, moving_item)
	from_container.set_slot(from_slot, target_item)
