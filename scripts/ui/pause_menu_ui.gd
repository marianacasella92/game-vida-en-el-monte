extends Control

## Panel del menú de pausa: construido por código, mismo estilo que
## marketplace_ui.gd. Necesario porque el juego corre en pantalla completa
## (project.godot: window/size/mode=fullscreen) — sin este menú no hay forma
## de cerrar la ventana sin matar el proceso a mano.

const PANEL_SIZE := Vector2(280, 180)

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)

	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.6)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)

	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = -PANEL_SIZE / 2.0
	panel.custom_minimum_size = PANEL_SIZE
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "Pausa"
	title.add_theme_font_size_override("font_size", 22)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)

	var resume_button := Button.new()
	resume_button.text = "Seguir jugando"
	resume_button.pressed.connect(_on_resume_pressed)
	vbox.add_child(resume_button)

	var quit_button := Button.new()
	quit_button.text = "Salir del juego"
	quit_button.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_button)

func _on_resume_pressed() -> void:
	get_tree().get_first_node_in_group("pause_system").close_pause()

func _on_quit_pressed() -> void:
	get_tree().quit()
