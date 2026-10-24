shader_type canvas_item;
void fragment() {
	vec4 p = texture(TEXTURE, UV);
	float light = dot(p.rgb,vec3(0.299,0.587,0.114));
	bool moss = p.g > p.r * 0.92 && p.g > p.b * 1.15;
	vec3 low = moss ? vec3(0.20,0.12,0.36) : vec3(0.12,0.075,0.20);
	vec3 high = moss ? vec3(0.76,0.53,0.88) : vec3(0.49,0.29,0.53);
	COLOR = vec4(mix(low,high,clamp(light*1.6,0.0,1.0)),p.a);
}
