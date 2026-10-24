shader_type spatial;
render_mode unshaded;
void fragment() {
	vec2 uv = UV;
	float grid = step(.96, fract(uv.x*12.0)) + step(.96, fract(uv.y*7.0));
	float wave = .5 + sin(uv.x*18.0 + TIME*.8)*.13 + sin(uv.x*43.0 - TIME)*.055;
	float trace = 1.0-smoothstep(.012,.027,abs(uv.y-wave));
	float scan = .82+.18*sin(uv.y*180.0);
	vec3 color = vec3(.025,.11,.16) + grid*.024 + trace*vec3(.28,.66,.59);
	color += step(uv.x,.18)*step(uv.y,.10)*vec3(.3,.48,.47);
	ALBEDO = color*scan;
}
