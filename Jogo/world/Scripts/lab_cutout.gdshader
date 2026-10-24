shader_type canvas_item;
uniform float alpha_cutoff : hint_range(0.0, 1.0) = 0.94;
uniform vec4 native_clip_box = vec4(0.0);
uniform int clip_count = 0;
uniform vec4 clip_boxes[32];
varying vec4 actor_tint;
void vertex() { actor_tint = COLOR; }
void fragment() {
    vec2 at = UV / TEXTURE_PIXEL_SIZE;
    for (int i=0; i<32; i++) {
        if (i>=clip_count) break;
        vec4 box=clip_boxes[i];
        if (at.x>=box.x && at.y>=box.y && at.x<box.x+box.z && at.y<box.y+box.w) discard;
    }
    if (native_clip_box.z > 0.0 && at.x >= native_clip_box.x && at.y >= native_clip_box.y && at.x < native_clip_box.x + native_clip_box.z && at.y < native_clip_box.y + native_clip_box.w) discard;
    vec4 ink = texture(TEXTURE, UV);
    if (ink.a < alpha_cutoff) discard;
    COLOR = vec4(ink.rgb, 1.0) * actor_tint;
}
