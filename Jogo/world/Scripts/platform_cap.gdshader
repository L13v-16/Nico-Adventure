shader_type canvas_item;

// TileMap's atlas adds a one-pixel gutter around each 16px tile.
// This is the left end; the tile's horizontal flip supplies the right end.
varying vec4 cap_tint;

void vertex() {
	cap_tint = COLOR;
}

void fragment() {
	vec4 ink = texture(TEXTURE, UV);
	vec2 pixel = mod(UV * vec2(textureSize(TEXTURE, 0)) - vec2(1.0), vec2(18.0));
	float cut = max(0.0, floor((pixel.y - 8.0) * 0.75));
	if (pixel.x < cut) {
		discard;
	}
	if ((pixel.y > 4.0 && pixel.x < cut + 1.0) || pixel.y > 14.5) {
		ink.rgb *= 0.68;
	}
	COLOR = ink * cap_tint;
}