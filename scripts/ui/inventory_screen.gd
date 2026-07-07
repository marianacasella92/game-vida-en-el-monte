extends Control

## Pantalla de mochila (PXD_Diseno_HUD_UI_v1.md, sección 4). Construida por
## código en _ready(), mismo estilo que marketplace_ui.gd/catalog_menu.gd, en
## vez de armar el layout a mano en el editor.
##
## Muestra dos almacenes separados, en una única fila centrada verticalmente
## en la pantalla (ver "outer" en _ready()): la grilla de mochila (Backpack,
## 5x6) a la izquierda, y una fila horizontal chica de hotbar (Hotbar,
## tamaño dinámico, ícono de tecla 1-9 arriba de cada slot) empujada al
## borde derecho. Arrastrar un ítem entre ambos mueve/intercambia entre
## Backpack.items y Hotbar.items vía move_item().

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

## la mochila se cierra con Q (acción close_window) — Esc es exclusivo del
## menú de pausa, ver docs/ESTANDARES_TECNICOS.md
const CLOSE_KEY_ICON := preload("res://assets/hud/keyset/White/Q.png")

const SLOT_SIZE := Vector2(72, 72)
const HOTBAR_SLOT_SIZE := Vector2(56, 56)
const KEY_ICON_SIZE := Vector2(24, 24)
const GRID_COLUMNS := 5

## Alto (en px) del bloque título+línea+label de la mochila (header ~34 +
## separación 20 + línea divisoria 11 + separación 20 + label "Mochila" ~20 +
## separación 20 ≈ 125) — se usa como relleno arriba del hotbar para que
## arranque a la misma altura que la grilla, ya que ambos viven ahora en la
## misma fila (ver _ready(): "outer").
const HOTBAR_TOP_OFFSET := 125.0

var money_label: Label
var backpack_grid: GridContainer
var hotbar_list: HBoxContainer
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

	# Todo el contenido (mochila + hotbar) vive en una única fila ("outer"),
	# centrada verticalmente como bloque en la pantalla completa: anclada al
	# 50% vertical con grow_vertical=BOTH, que hace que Godot calcule su alto
	# real a partir del contenido y la centre sola, creciendo para los dos
	# lados por igual. Así mochila y hotbar quedan siempre alineadas entre sí
	# (comparten el mismo "arriba" de fila) sin sincronizar a mano dos
	# bloques anclados por separado como antes.
	var outer := HBoxContainer.new()
	outer.anchor_left = 0.0
	outer.anchor_right = 1.0
	outer.anchor_top = 0.5
	outer.anchor_bottom = 0.5
	outer.grow_vertical = Control.GROW_DIRECTION_BOTH
	add_child(outer)

	# Columna de la mochila: se expande para absorber todo el espacio
	# sobrante entre su contenido (angosto) y la columna del hotbar (a la
	# derecha) — ese sobrante es precisamente el "aire" del medio de la
	# pantalla, sin necesidad de fijarle un ancho de mitad de pantalla.
	#
	# Va directo como MarginContainer (no como Control envolviendo un
	# MarginContainer anclado adentro): un Control común no reporta el
	# tamaño mínimo de sus hijos hacia arriba, y sin eso "outer" no puede
	# calcular cuánto mide realmente la mochila para centrar el bloque
	# entero — terminaba centrando una caja mucho más chica que el
	# contenido real, que se desbordaba por abajo sin avisar.
	var margin := MarginContainer.new()
	margin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_theme_constant_override("margin_left", 140)
	margin.add_theme_constant_override("margin_top", 0)
	margin.add_theme_constant_override("margin_right", 0)
	margin.add_theme_constant_override("margin_bottom", 0)
	outer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
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
	money_icon.custom_minimum_size = Vector2(28, 28)
	header.add_child(money_icon)

	money_label = Label.new()
	money_label.add_theme_font_override("font", FONT_TITLE)
	money_label.add_theme_font_size_override("font_size", 20)
	money_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	header.add_child(money_label)

	# La línea se repite (tile) en vez de estirarse: es un trazo hecho a
	# mano, estirarlo la deforma.
	var divider_top := TextureRect.new()
	divider_top.texture = DIVIDER_TOP
	divider_top.stretch_mode = TextureRect.STRETCH_TILE
	divider_top.custom_minimum_size = Vector2(0, 11)
	divider_top.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(divider_top)

	var backpack_label := Label.new()
	backpack_label.text = "Mochila"
	backpack_label.add_theme_font_override("font", FONT_BODY)
	backpack_label.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	vbox.add_child(backpack_label)

	backpack_grid = GridContainer.new()
	backpack_grid.columns = GRID_COLUMNS
	backpack_grid.add_theme_constant_override("h_separation", 14)
	backpack_grid.add_theme_constant_override("v_separation", 14)
	vbox.add_child(backpack_grid)
	for slot in range(Backpack.SLOT_COUNT):
		_backpack_slots.append(_make_slot(InventorySlot.Store.BACKPACK, slot, backpack_grid))

	# La línea de abajo (ya trae el isotipo del juego) no se estira ni se
	# repite: se muestra una sola vez a su tamaño real, pegada a la
	# izquierda. size_flags_horizontal = SHRINK_BEGIN es necesario acá: sin
	# eso, el VBoxContainer la estira igual al ancho completo de la columna
	# (comportamiento default de todo hijo de un contenedor) y stretch_mode
	# default (STRETCH_SCALE) la deforma para llenar ese ancho.
	var divider_bottom := TextureRect.new()
	divider_bottom.texture = DIVIDER_BOTTOM
	divider_bottom.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	vbox.add_child(divider_bottom)

	# Hotbar: columna angosta al final de la misma fila "outer", empujada a
	# la derecha por el expand-fill de la columna de la mochila. margin_right le da aire
	# contra el borde derecho de la pantalla.
	var right_margin := MarginContainer.new()
	right_margin.add_theme_constant_override("margin_right", 120)
	outer.add_child(right_margin)

	var hotbar_section := VBoxContainer.new()
	hotbar_section.add_theme_constant_override("separation", 6)
	right_margin.add_child(hotbar_section)

	# Relleno para que la fila del hotbar arranque a la misma altura que la
	# grilla de la mochila (después de su título+línea+label), ya que ambas
	# columnas comparten el mismo punto de partida vertical en "outer".
	var hotbar_top_spacer := Control.new()
	hotbar_top_spacer.custom_minimum_size = Vector2(0, HOTBAR_TOP_OFFSET)
	hotbar_section.add_child(hotbar_top_spacer)

	var hotbar_label := Label.new()
	hotbar_label.text = "Accesos rápidos"
	hotbar_label.add_theme_font_override("font", FONT_BODY)
	hotbar_section.add_child(hotbar_label)

	hotbar_list = HBoxContainer.new()
	hotbar_list.add_theme_constant_override("separation", 10)
	hotbar_section.add_child(hotbar_list)
	for slot in range(Hotbar.SLOT_COUNT):
		_hotbar_slots.append(_make_hotbar_slot(slot, hotbar_list))

	# Recordatorio de cómo cerrar, abajo a la derecha — anclado por la
	# esquina (grow_horizontal/vertical = BEGIN) para que crezca hacia
	# adentro de la pantalla según el tamaño real del ícono + texto, en vez
	# de tener que adivinarle un ancho fijo.
	var esc_hint := HBoxContainer.new()
	esc_hint.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	esc_hint.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	esc_hint.grow_vertical = Control.GROW_DIRECTION_BEGIN
	esc_hint.offset_left = -72
	esc_hint.offset_right = -72
	esc_hint.offset_top = -48
	esc_hint.offset_bottom = -48
	esc_hint.add_theme_constant_override("separation", 8)
	add_child(esc_hint)

	var esc_icon := TextureRect.new()
	esc_icon.texture = CLOSE_KEY_ICON
	esc_icon.custom_minimum_size = Vector2(28, 28)
	esc_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	esc_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	esc_hint.add_child(esc_icon)

	var esc_label := Label.new()
	esc_label.text = "Volver"
	esc_label.add_theme_font_override("font", FONT_BODY)
	esc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	esc_hint.add_child(esc_label)

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

## Una columna del hotbar (ícono de tecla arriba, slot chico abajo) para la
## fila horizontal de la esquina inferior derecha. slot_index es 0-based;
## KEY_ICONS ya está indexado igual. Los slots son más chicos que los de la
## mochila (HOTBAR_SLOT_SIZE) para que no compitan en tamaño con ella.
func _make_hotbar_slot(slot_index: int, parent: Container) -> InventorySlot:
	var column := VBoxContainer.new()
	column.add_theme_constant_override("separation", 4)
	column.alignment = BoxContainer.ALIGNMENT_CENTER
	parent.add_child(column)

	var key_icon := TextureRect.new()
	key_icon.custom_minimum_size = KEY_ICON_SIZE
	key_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	key_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	key_icon.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if slot_index < KEY_ICONS.size():
		key_icon.texture = KEY_ICONS[slot_index]
	column.add_child(key_icon)

	var slot := _make_slot(InventorySlot.Store.HOTBAR, slot_index, column)
	slot.custom_minimum_size = HOTBAR_SLOT_SIZE
	slot.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	return slot

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
