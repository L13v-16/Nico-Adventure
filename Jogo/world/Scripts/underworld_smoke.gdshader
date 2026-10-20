shader_type canvas_item;
render_mode unshaded;

uniform sampler2D smoke_noise : repeat_enable, filter_linear;
uniform bool foreground = false;
uniform float elapsed = 0.0;
uniform float camera_x = 0.0;

void fragment() {
	// Two-pixel steps keep the soft smoke in the game's pixel-art resolution.
	vec2 screen = floor(UV * vec2(320.0, 180.0)) / vec2(320.0, 180.0);
	float depth = foreground ? 1.0 : 0.0;
	vec2 drift = vec2(elapsed * (0.011 + depth * 0.006), -elapsed * 0.008);
	vec2 sample_uv = screen * vec2(1.25, 0.8) + drift;
	sample_uv.x += camera_x * (0.000045 + depth * 0.000035);
	float broad = texture(smoke_noise, sample_uv).r;
	float wisps = texture(smoke_noise, sample_uv * vec2(1.7, 2.4) - drift * 0.65 + 0.37).r;
	float cloud = smoothstep(0.32, 0.75, broad * 0.7 + wisps * 0.3);
	float floor_bank = smoothstep(0.28 + broad * 0.23, 1.05, screen.y);
	float side_bank = pow(abs(screen.x * 2.0 - 1.0), 3.0) * 0.3;
	float coverage = foreground ? floor_bank + side_bank : 0.38 + floor_bank * 0.5;
	float opacity = foreground ? 0.25 : 0.23;
	vec3 ash = foreground ? vec3(0.45, 0.36, 0.40) : vec3(0.48, 0.39, 0.51);
	COLOR = vec4(ash, clamp(cloud * coverage * opacity, 0.0, 0.18));
}
