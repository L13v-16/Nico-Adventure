shader_type spatial;
void fragment() {
	vec2 cells = UV*vec2(7.0,14.0);
	vec2 part = fract(cells);
	float window = step(.16,part.x)*(1.0-step(.82,part.x))*step(.18,part.y)*(1.0-step(.72,part.y));
	float occupied = step(.48,fract(sin(dot(floor(cells),vec2(12.98,78.23)))*43758.54));
	vec3 glass = mix(vec3(.17,.30,.38),vec3(.55,.65,.61),occupied);
	ALBEDO = mix(vec3(.26,.35,.41),glass,window);
	ROUGHNESS = .65;
	METALLIC = .18;
}
