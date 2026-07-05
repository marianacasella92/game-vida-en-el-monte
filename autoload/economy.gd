extends Node

## Autoload de economía: plata + ítems comprados en el marketplace (Milestone 3).

signal money_changed(new_amount: int)
signal item_purchased(item_id: String)

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

func purchase_item(item_id: String, price: int) -> bool:
	if purchased_items.has(item_id):
		return false
	if not spend_money(price):
		return false
	purchased_items[item_id] = true
	item_purchased.emit(item_id)
	return true
