extends CanvasLayer

@onready var money_label: Label = $MoneyLabel
@onready var hunger_bar: ProgressBar = $HungerBar
@onready var sleep_bar: ProgressBar = $SleepBar

func _ready() -> void:
	Economy.money_changed.connect(_update_money)
	Inventory.inventory_changed.connect(_update_money)
	PlayerNeeds.hunger_changed.connect(_update_hunger)
	PlayerNeeds.sleep_changed.connect(_update_sleep)
	_update_money()
	_update_hunger(PlayerNeeds.hunger)
	_update_sleep(PlayerNeeds.sleep)

func _update_money(_arg = null) -> void:
	var item: Dictionary = Inventory.get_selected_item()
	var item_name: String = item.get("name", "Vacío")
	money_label.text = "$ %d | Mano: %s" % [Economy.money, item_name]

func _update_hunger(value: float) -> void:
	hunger_bar.value = value
	# feedback simple: la barra se pone roja con hambre baja, en vez de un
	# texto/popup — mismo criterio que ya usa el proyecto (color = estado)
	hunger_bar.modulate = Color(1.0, 0.35, 0.35) if value <= PlayerNeeds.max_hunger * 0.25 else Color.WHITE

func _update_sleep(value: float) -> void:
	sleep_bar.value = value
	sleep_bar.modulate = Color(0.5, 0.6, 1.0) if value <= PlayerNeeds.max_sleep * 0.25 else Color.WHITE
