shader_type canvas_item;

// Preserve the generated character palette and remove faint matte remnants.
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.78;
varying vec4 actor_tint;

void vertex() {
	actor_tint = COLOR;
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	if (ink.a < alpha_cutoff) {
		discard;
	}
	COLOR = vec4(ink.rgb, 1.0) * actor_tint;
}
