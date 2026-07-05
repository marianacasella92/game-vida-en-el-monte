extends Label

func _ready() -> void:
	_update_text(Economy.money)
	Economy.money_changed.connect(_update_text)

func _update_text(new_amount: int) -> void:
	text = "$ %d" % new_amount
