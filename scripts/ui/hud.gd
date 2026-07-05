extends CanvasLayer

## HUD de vitales (docs/GameDesign/PXD_Diseno_HUD_UI_v1.md, sección 2):
## corazón standalone (sin barra) para vida, manzana+barra para hambre,
## rayo+barra para energía — 100% assets reales (assets/hud/), nada dibujado
## por código salvo el relleno blanco liso de las barras (no hay un asset de
## relleno separado, solo el marco vacío).

@onready var root: Control = $Root
@onready var health_icon: TextureRect = $Root/HealthIcon
@onready var hunger_bar: TextureProgressBar = $Root/HungerRow/HungerBar
@onready var energy_bar: TextureProgressBar = $Root/EnergyRow/EnergyBar

@onready var build_system: Node = get_tree().get_first_node_in_group("build_system")
@onready var work_system: Node = get_tree().get_first_node_in_group("work_system")
@onready var phone_system: Node = get_tree().get_first_node_in_group("phone_system")
@onready var inventory_system: Node = get_tree().get_first_node_in_group("inventory_system")

func _ready() -> void:
	var fill := _make_fill_texture()
	hunger_bar.texture_progress = fill
	energy_bar.texture_progress = fill

	PlayerNeeds.hunger_changed.connect(_update_hunger)
	PlayerNeeds.sleep_changed.connect(_update_energy)

	_update_hunger(PlayerNeeds.hunger)
	_update_energy(PlayerNeeds.sleep)

## bar_hunger.png/bar_energy.png son solo el marco vacío — no hay un sprite de
## relleno generado, así que se arma uno blanco liso de 1x1 acá, que
## TextureProgressBar estira y recorta según el valor.
func _make_fill_texture() -> ImageTexture:
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.WHITE)
	return ImageTexture.create_from_image(image)

## PXD_Diseno_HUD_UI_v1.md, sección 5: el HUD de vitales se oculta por
## completo mientras hay una pantalla modal abierta (catálogo, celular,
## trabajando), y vuelve a aparecer al cerrarla.
func _process(_delta: float) -> void:
	var modal_open: bool = (
		(build_system and build_system.menu_open)
		or (work_system and work_system.is_working)
		or (phone_system and phone_system.is_open)
		or (inventory_system and inventory_system.is_open)
	)
	root.visible = not modal_open

func _update_hunger(value: float) -> void:
	hunger_bar.value = value

func _update_energy(value: float) -> void:
	energy_bar.value = value
