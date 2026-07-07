extends "res://scripts/build/proximity_interactable.gd"

## Cama: dormir restaura el sueño al máximo — sin transición de día/noche
## todavía (eso es Sprint 4.4), ni animación de dormir. Proximidad, prompt y
## guardas de pantallas modales viven en proximity_interactable.gd.

func _on_interact() -> void:
	PlayerNeeds.sleep_now()
	print("[needs] durmió, sueño=%.0f" % PlayerNeeds.sleep)
