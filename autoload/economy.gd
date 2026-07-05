extends Node

## Autoload mínimo de economía: solo guarda la plata y avisa cuando cambia.
## La UI de marketplace para gastarla es Milestone 3.

signal money_changed(new_amount: int)

var money: int = 0

func add_money(amount: int) -> void:
	money += amount
	money_changed.emit(money)
