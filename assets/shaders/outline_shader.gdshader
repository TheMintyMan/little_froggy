shader_type spatial;
render_mode cull_front, unshaded;

uniform vec4 outline_color : source_color = vec4(0.0, 0.0, 0.0, 1.0);
uniform float outline_width = 2.0; // in pixels

void vertex() {
	vec4 clip_position = PROJECTION_MATRIX * (MODELVIEW_MATRIX * vec4(VERTEX, 1.0));
	vec3 clip_normal = mat3(PROJECTION_MATRIX) * (mat3(MODELVIEW_MATRIX) * NORMAL);

	// push the back faces outward on screen; guard against normals pointing straight at the camera
	vec2 dir = clip_normal.xy;
	vec2 offset = (length(dir) > 0.0001 ? normalize(dir) : vec2(0.0)) / VIEWPORT_SIZE * clip_position.w * outline_width * 2.0;

	clip_position.xy += offset;
	POSITION = clip_position;
}

void fragment() {
	ALBEDO = outline_color.rgb;
	if (outline_color.a < 1.0) {
		ALPHA = outline_color.a;
	}
}
