shader_type canvas_item;

// Blur gaussiano simple (9-tap) + oscurecido, para el fondo de pantallas
// modales tipo la mochila (PXD_Diseno_HUD_UI_v1.md, sección 4): el mundo 3D
// sigue visible detrás, pero desenfocado y atenuado — nunca corta a negro.
//
// Godot 4: SCREEN_TEXTURE ya no existe como built-in (era de Godot 3) — hay
// que declararla como uniform con hint_screen_texture. Este shader estuvo
// roto (sin compilar) desde que se creó por usar la sintaxis vieja: el
// inventario se veía oscurecido igual solo porque su ColorRect tiene color
// negro de fallback, pero nunca hubo blur de verdad (bug real 07/07/2026,
// descubierto al repetir el mismo error en low_health_vignette.gdshader).
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float blur_amount : hint_range(0.0, 10.0) = 4.0;
uniform float darken_amount : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 offset = SCREEN_PIXEL_SIZE * blur_amount;
	vec4 sum = vec4(0.0);
	sum += texture(screen_texture, SCREEN_UV + vec2(-offset.x, -offset.y));
	sum += texture(screen_texture, SCREEN_UV + vec2(0.0, -offset.y));
	sum += texture(screen_texture, SCREEN_UV + vec2(offset.x, -offset.y));
	sum += texture(screen_texture, SCREEN_UV + vec2(-offset.x, 0.0));
	sum += texture(screen_texture, SCREEN_UV);
	sum += texture(screen_texture, SCREEN_UV + vec2(offset.x, 0.0));
	sum += texture(screen_texture, SCREEN_UV + vec2(-offset.x, offset.y));
	sum += texture(screen_texture, SCREEN_UV + vec2(0.0, offset.y));
	sum += texture(screen_texture, SCREEN_UV + vec2(offset.x, offset.y));
	vec4 blurred = sum / 9.0;
	COLOR = vec4(blurred.rgb * (1.0 - darken_amount), 1.0);
}
