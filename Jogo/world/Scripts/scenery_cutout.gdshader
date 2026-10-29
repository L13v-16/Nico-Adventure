shader_type canvas_item;

// Generated sprites retain their source alpha; scenery uses hard pixel edges.
varying vec4 sprite_tint;

void vertex() {
	sprite_tint = COLOR;
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	float value = dot(ink.rgb, vec3(0.2126, 0.7152, 0.0722));
	vec3 palette = mix(vec3(value), ink.rgb, 0.8);
	COLOR = vec4(palette, step(0.78, ink.a)) * sprite_tint;
}
