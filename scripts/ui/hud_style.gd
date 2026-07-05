class_name HudStyle
extends RefCounted

## Estilos compartidos para toda la UI en pantalla (HUD, y más adelante
## hotbar/notificaciones/banner de eventos) — un solo lugar para el lenguaje
## visual, en vez de repetir StyleBoxFlat sueltos en cada script. Ver
## docs/GameDesign/PXD_Documento_Fundacional_v0.2.md: sin colores saturados
## tipo semáforo, bordes finos y rectos (no redondeados tipo app casual).

const COLOR_BG := Color(0.05, 0.05, 0.05, 0.55)
const COLOR_BORDER := Color(1.0, 1.0, 1.0, 0.4)
const BORDER_WIDTH := 1
const CORNER_RADIUS := 2

## Tintes de relleno desaturados por stat — apagados a propósito, no rojo/celeste puro.
const TINT_HEALTH := Color(0.65, 0.28, 0.28)
const TINT_ENERGY := Color(0.35, 0.42, 0.62)
const TINT_HUNGER := Color(0.68, 0.55, 0.32)

static func bar_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = COLOR_BORDER
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.anti_aliasing = true
	return style

static func bar_fill(tint: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = tint
	style.set_corner_radius_all(CORNER_RADIUS)
	style.anti_aliasing = true
	return style

## Mismo lenguaje visual que las barras, para paneles (notificaciones, banner
## de eventos en fases futuras).
static func panel_background() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = COLOR_BG
	style.border_color = COLOR_BORDER
	style.set_border_width_all(BORDER_WIDTH)
	style.set_corner_radius_all(CORNER_RADIUS)
	style.anti_aliasing = true
	return style
