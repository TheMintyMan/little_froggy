shader_type spatial;

// base look (matches the StandardMaterial3D it replaces)
uniform sampler2D albedo_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 albedo_color : source_color = vec4(1.0);
uniform float roughness : hint_range(0.0, 1.0) = 0.8;

// clouds (same settings as ground_shader)
uniform sampler2D cloud_noise : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 cloud_scale = vec2(0.01);
uniform vec2 cloud_speed = vec2(0.005);
uniform float cloud_height = 15.5;

varying vec3 world_pos;
varying mat4 world_mat;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	world_mat = INV_VIEW_MATRIX;
}

void fragment() {
	ALBEDO = albedo_color.rgb * texture(albedo_texture, UV).rgb;
	ROUGHNESS = roughness;
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		// ray from the surface toward the sun, in world space
		vec3 ray_dir = mat3(world_mat) * LIGHT;
		// where that ray crosses the cloud layer
		float t = (cloud_height - world_pos.y) / ray_dir.y;
		vec3 P = world_pos + t * ray_dir;

		vec2 uv_offset = vec2(TIME) * cloud_speed;
		vec4 rg = textureLod(cloud_noise, P.xz * cloud_scale + uv_offset, 3.0);

		float clouds = smoothstep(0.2, 1.0, 1.0 - rg.r);
		// make it less dark
		clouds = clouds * 0.9 + 0.1;

		float shadow = ATTENUATION;
		if (clouds < 1.0 && shadow < 1.0) {
			shadow *= 1.0 - 0.2 * smoothstep(0.1, 1.0, rg.r);
			shadow += 0.2 * smoothstep(0.1, 1.0, rg.r);
			clouds = min(clouds, shadow);
		}

		DIFFUSE_LIGHT += clamp(dot(NORMAL, LIGHT), 0.0, 1.0) * clouds * shadow * ALBEDO * LIGHT_COLOR;
	}
}
