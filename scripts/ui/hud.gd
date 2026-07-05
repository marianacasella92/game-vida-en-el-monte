extends CanvasLayer

## HUD minimalista (docs/GameDesign/PXD_Documento_Fundacional_v0.2.md): sin
## colores saturados tipo semáforo — el feedback de "atención acá" es un
## ícono de advertencia que aparece/desaparece, no un cambio de color de la
## barra entera. Estilos compartidos en scripts/ui/hud_style.gd.

const BATTERY_FULL := preload("res://assets/hud/Icon set 1/1x/Battery - full 512 px.png")
const BATTERY_LOW := preload("res://assets/hud/Icon set 1/1x/Low battery 512 px.png")
const BATTERY_EMPTY := preload("res://assets/hud/Icon set 1/1x/Empty battery  512 px.png")

@onready var health_bar: ProgressBar = $Root/HealthRow/HealthBar
@onready var health_warning: TextureRect = $Root/HealthRow/HealthWarning
@onready var energy_icon: TextureRect = $Root/EnergyRow/EnergyIcon
@onready var energy_bar: ProgressBar = $Root/EnergyRow/EnergyBar
@onready var energy_warning: TextureRect = $Root/EnergyRow/EnergyWarning
@onready var hunger_bar: ProgressBar = $Root/HungerRow/HungerBar
@onready var hunger_warning: TextureRect = $Root/HungerRow/HungerWarning
@onready var money_label: Label = $Root/MoneyRow/MoneyLabel

func _ready() -> void:
	for bar in [health_bar, energy_bar, hunger_bar]:
		bar.add_theme_stylebox_override("background", HudStyle.bar_background())

	health_bar.add_theme_stylebox_override("fill", HudStyle.bar_fill(HudStyle.TINT_HEALTH))
	energy_bar.add_theme_stylebox_override("fill", HudStyle.bar_fill(HudStyle.TINT_ENERGY))
	hunger_bar.add_theme_stylebox_override("fill", HudStyle.bar_fill(HudStyle.TINT_HUNGER))

	Economy.money_changed.connect(_update_money)
	PlayerNeeds.health_changed.connect(_update_health)
	PlayerNeeds.sleep_changed.connect(_update_energy)
	PlayerNeeds.hunger_changed.connect(_update_hunger)

	_update_money(Economy.money)
	_update_health(PlayerNeeds.health)
	_update_energy(PlayerNeeds.sleep)
	_update_hunger(PlayerNeeds.hunger)

func _update_money(new_amount: int) -> void:
	money_label.text = "%d" % new_amount

func _update_health(value: float) -> void:
	health_bar.value = value
	health_warning.visible = value <= PlayerNeeds.max_health * PlayerNeeds.neglect_threshold_ratio

func _update_energy(value: float) -> void:
	energy_bar.value = value
	var ratio: float = value / PlayerNeeds.max_sleep
	if ratio <= PlayerNeeds.neglect_threshold_ratio:
		energy_icon.texture = BATTERY_EMPTY
	elif ratio <= 0.5:
		energy_icon.texture = BATTERY_LOW
	else:
		energy_icon.texture = BATTERY_FULL
	energy_warning.visible = ratio <= PlayerNeeds.neglect_threshold_ratio

func _update_hunger(value: float) -> void:
	hunger_bar.value = value
	hunger_warning.visible = value <= PlayerNeeds.max_hunger * PlayerNeeds.neglect_threshold_ratio
