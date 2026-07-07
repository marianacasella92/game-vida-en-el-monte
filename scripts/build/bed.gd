extends "res://scripts/build/proximity_interactable.gd"

## Cama: dormir restaura el sueño al máximo, salta el reloj a la mañana
## siguiente (TimeManager.wake_hour, ver config/day_night.cfg) y dispara el
## autoguardado REAL del GDD 4.10 ("el autoguardado ocurre en momentos
## naturales, ej. al dormir") — el timer periódico de SaveManager queda como
## red de seguridad. Sin animación de dormir todavía. Proximidad, prompt y
## guardas de pantallas modales viven en proximity_interactable.gd.

func _on_interact() -> void:
	PlayerNeeds.sleep_now()
	TimeManager.skip_to_morning()
	SaveManager.save_game()
	DevMode.debug_log("needs", "durmió — día %d, %s, sueño=%.0f" % [TimeManager.day, TimeManager.clock_text(), PlayerNeeds.sleep])
