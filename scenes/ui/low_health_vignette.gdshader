shader_type canvas_item;

// Efecto de vida baja (PXD_Diseno_HUD_UI_v1.md, sección 2.4): viñeta oscura
// + leve desenfoque radial en los bordes de pantalla. El centro queda
// despejado — la sensación es "se me nubla la vista", no una pantalla sucia.
// `intensity` (0..1) la maneja hud.gd según el valor de vida actual: 0 =
// invisible (vida sana), 1 = efecto completo (al borde del desmayo).
//
// Godot 4: SCREEN_TEXTURE ya no existe como built-in (era de Godot 3) — hay
// que declararla como uniform con hint_screen_texture. Con la sintaxis vieja
// el shader no compila y el ColorRect se dibuja con su color plano (pantalla
// blanca, bug real 07/07/2026).
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;

uniform float intensity : hint_range(0.0, 1.0) = 0.0;
uniform float max_blur : hint_range(0.0, 10.0) = 5.0;
uniform float vignette_darkness : hint_range(0.0, 1.0) = 0.75;
// Pulso lento tipo "respiración pesada": la viñeta se contrae y afloja de a
// poco en vez de quedarse estática. pulse_speed ≈ 2.5 da un ciclo de ~2.5s,
// parecido a una respiración agitada. pulse_amount = 0 la deja fija.
uniform float pulse_amount : hint_range(0.0, 1.0) = 0.3;
uniform float pulse_speed : hint_range(0.0, 10.0) = 2.5;

void fragment() {
	// 0 en el centro de la pantalla, 1 en las esquinas.
	float edge = smoothstep(0.25, 0.75, distance(SCREEN_UV, vec2(0.5)));
	float pulse = 1.0 - pulse_amount * (0.5 + 0.5 * sin(TIME * pulse_speed));
	float effect = edge * intensity * pulse;

	vec2 offset = SCREEN_PIXEL_SIZE * max_blur * effect;
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

	COLOR = vec4(blurred.rgb * (1.0 - vignette_darkness * effect), 1.0);
}
