shader_type canvas_item;

// Blur gaussiano simple (9-tap) + oscurecido, para el fondo de pantallas
// modales tipo la mochila (PXD_Diseno_HUD_UI_v1.md, sección 4): el mundo 3D
// sigue visible detrás, pero desenfocado y atenuado — nunca corta a negro.
// Primer shader del proyecto: si no se ve bien en el renderer Compatibility,
// el fallback simple es sacar el material de este ColorRect y dejarlo solo
// como oscurecido semitransparente sin blur.

uniform float blur_amount : hint_range(0.0, 10.0) = 4.0;
uniform float darken_amount : hint_range(0.0, 1.0) = 0.45;

void fragment() {
	vec2 offset = SCREEN_PIXEL_SIZE * blur_amount;
	vec4 sum = vec4(0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(-offset.x, -offset.y), 0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, -offset.y), 0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(offset.x, -offset.y), 0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(-offset.x, 0.0), 0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV, 0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(offset.x, 0.0), 0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(-offset.x, offset.y), 0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(0.0, offset.y), 0.0);
	sum += textureLod(SCREEN_TEXTURE, SCREEN_UV + vec2(offset.x, offset.y), 0.0);
	vec4 blurred = sum / 9.0;
	COLOR = vec4(blurred.rgb * (1.0 - darken_amount), 1.0);
}
