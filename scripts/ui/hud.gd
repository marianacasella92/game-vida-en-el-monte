extends CanvasLayer

## HUD de vitales (docs/GameDesign/PXD_Diseno_HUD_UI_v1.md, sección 2):
## corazón standalone (sin barra) para vida, manzana+barra para hambre,
## rayo+barra para energía — 100% assets reales (assets/hud/).
##
## bar_hunger.png/bar_energy.png son solo el marco vacío (dibujado a mano,
## con textura de tiza); bar_fill.png es el relleno, compartido entre las
## dos barras porque es el mismo trazo para ambas.
const FILL_TEXTURE := preload("res://assets/hud/bar_fill.png")

@onready var root: Control = $Root
## Corazón en dos capas (assets separados por la usuaria a partir del
## icon_health.png original): el marco circular queda fijo encima, y el
## corazón de abajo es un TextureProgressBar vertical (fill_mode
## BOTTOM_TO_TOP) que se va "recortando" de arriba hacia abajo a medida que
## baja la vida — lleno = 100%, vacío = 0% = desmayo.
@onready var heart_fill: TextureProgressBar = $Root/HealthIcon/HeartFill
@onready var hunger_bar: TextureProgressBar = $Root/StatsColumn/HungerRow/HungerBar
@onready var energy_bar: TextureProgressBar = $Root/StatsColumn/EnergyRow/EnergyBar
@onready var death_message: Label = $DeathMessage
@onready var low_health_vignette: ColorRect = $LowHealthVignette

const DEATH_MESSAGE_DURATION := 4.0

## PXD 2.4: por debajo de esta fracción de vida empieza el efecto de "vista
## nublada" (viñeta + desenfoque en los bordes, ver low_health_vignette.gdshader),
## creciendo hasta el máximo al llegar a 0 (desmayo). Acompaña al debuff de
## movimiento que ya existe (PlayerNeeds.get_move_speed_multiplier()).
const VIGNETTE_HEALTH_THRESHOLD := 0.5
var _vignette_intensity: float = 0.0

@onready var build_system: Node = get_tree().get_first_node_in_group("build_system")
@onready var work_system: Node = get_tree().get_first_node_in_group("work_system")
@onready var phone_system: Node = get_tree().get_first_node_in_group("phone_system")
@onready var inventory_system: Node = get_tree().get_first_node_in_group("inventory_system")
@onready var pause_system: Node = get_tree().get_first_node_in_group("pause_system")

func _ready() -> void:
	hunger_bar.texture_progress = FILL_TEXTURE
	energy_bar.texture_progress = FILL_TEXTURE

	heart_fill.max_value = PlayerNeeds.max_health

	PlayerNeeds.hunger_changed.connect(_update_hunger)
	PlayerNeeds.sleep_changed.connect(_update_energy)
	PlayerNeeds.health_changed.connect(_update_health)
	PlayerNeeds.died.connect(_on_player_died)

	_update_hunger(PlayerNeeds.hunger)
	_update_energy(PlayerNeeds.sleep)
	_update_health(PlayerNeeds.health)

## PXD_Diseno_HUD_UI_v1.md, sección 5: el HUD de vitales se oculta por
## completo mientras hay una pantalla modal abierta (catálogo, celular,
## trabajando), y vuelve a aparecer al cerrarla.
func _process(_delta: float) -> void:
	var modal_open: bool = (
		(build_system and build_system.menu_open)
		or (work_system and work_system.is_working)
		or (phone_system and phone_system.is_open)
		or (inventory_system and inventory_system.is_open)
		or (pause_system and pause_system.is_open)
	)
	root.visible = not modal_open
	# la viñeta de vida baja también se apaga con pantallas modales: el Hud se
	# dibuja ENCIMA de esas capas (todas CanvasLayer con el mismo layer, y Hud
	# es el último en el árbol) — sin esto, el efecto se dibujaría sobre el
	# inventario/celular en vez de quedar detrás.
	low_health_vignette.visible = not modal_open and _vignette_intensity > 0.0

func _update_hunger(value: float) -> void:
	hunger_bar.value = value

func _update_energy(value: float) -> void:
	energy_bar.value = value

## Al cambiar la vida se actualizan las dos caras del mismo estado: el
## corazón del HUD (se vacía de arriba hacia abajo) y la viñeta de "vista
## nublada" — intensidad 0 con la vida por encima del umbral, 1 al llegar a 0;
## el shader hace el resto (viñeta + blur solo en los bordes). El ColorRect se
## oculta del todo con intensidad 0 para no pagar el costo del shader cuando
## no aporta nada (Compatibility renderer, hardware integrado). La
## visibilidad final la decide _process (también depende de si hay una
## pantalla modal abierta).
func _update_health(value: float) -> void:
	heart_fill.value = value
	var ratio: float = value / PlayerNeeds.max_health
	_vignette_intensity = clampf((VIGNETTE_HEALTH_THRESHOLD - ratio) / VIGNETTE_HEALTH_THRESHOLD, 0.0, 1.0)
	(low_health_vignette.material as ShaderMaterial).set_shader_parameter("intensity", _vignette_intensity)

## GDD 4.8: morir por hambre/sueño descuidado recarga el último guardado en
## silencio (save_manager.gd::_on_player_died) — sin este aviso, esa recarga
## se sentía como un bug random pisando la construcción en curso, en vez de la
## única penalización dura a propósito del juego.
func _on_player_died() -> void:
	death_message.visible = true
	await get_tree().create_timer(DEATH_MESSAGE_DURATION).timeout
	death_message.visible = false
