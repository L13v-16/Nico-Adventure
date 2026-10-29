shader_type canvas_item;
render_mode unshaded;
uniform float radius = 2.3;
void fragment() {
    vec2 p = TEXTURE_PIXEL_SIZE * radius;
    vec4 ink = texture(TEXTURE, UV) * 0.24;
    ink += texture(TEXTURE, UV + vec2(p.x, 0.0)) * 0.12;
    ink += texture(TEXTURE, UV - vec2(p.x, 0.0)) * 0.12;
    ink += texture(TEXTURE, UV + vec2(0.0, p.y)) * 0.12;
    ink += texture(TEXTURE, UV - vec2(0.0, p.y)) * 0.12;
    ink += texture(TEXTURE, UV + p) * 0.07;
    ink += texture(TEXTURE, UV - p) * 0.07;
    ink += texture(TEXTURE, UV + vec2(p.x,-p.y)) * 0.07;
    ink += texture(TEXTURE, UV + vec2(-p.x,p.y)) * 0.07;
    float grey = dot(ink.rgb, vec3(0.22,0.7,0.08));
    COLOR = vec4(mix(vec3(grey),ink.rgb,0.58) * vec3(0.52,0.59,0.65),ink.a);
}
