shader_type spatial;

uniform sampler2D texture_mask: source_color, repeat_enable;
uniform vec2 mask_scale = vec2(1.0, 1.0);
uniform vec2 mask_offset = vec2(0.0, 0.0);

uniform sampler2D texture_b: source_color, repeat_enable;
uniform bool use_texture_b = false;
uniform float texture_b_scale = 1.0;
uniform float texture_b_offset = 0.0;

uniform vec3 color_a: source_color = vec3(0.5,0.5,0.5);
uniform vec3 color_b: source_color = vec3(0.5,0.5,0.5);

uniform float blend_amount = 0.5;

// true = use the mesh's UVs for texture_b (for textures painted onto a UV layout)
uniform bool use_uv_mapping = false;

// clouds
uniform sampler2D cloud_noise : source_color, filter_linear_mipmap, repeat_enable;
varying vec3 world_pos;
uniform vec2 cloud_scale = vec2(0.01);
uniform vec2 cloud_speed = vec2(0.003);
uniform float cloud_height = 15.5;
uniform float coverage = 0.45;
uniform float softness = 0.7;
uniform float shadow_strength = 10;
uniform float cloud_mip : hint_range(0.0, 10.0) = 3.0;

varying mat4 world_mat;

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; // world position for the cloud shadow in light()
	world_mat = INV_VIEW_MATRIX;
}

void fragment() {
	vec4 vertex = INV_VIEW_MATRIX * vec4(VERTEX, 1.0);
	vec3 normal = normalize((INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
	// Calculate triplanar projection weights with normalized sum
vec3 adjusted_normal = pow(abs(normal), vec3(8.0));
vec3 weights = adjusted_normal / (adjusted_normal.x + adjusted_normal.y + adjusted_normal.z);

vec2 uv_x = vertex.zy;
vec2 uv_y = vertex.xz;
vec2 uv_z = vertex.xy;

/* STREAMING_CHUNK:Sampling triplanar mask texture... */
vec2 mask_uv_x = (uv_x * mask_scale.x) + mask_offset;
vec2 mask_uv_y = (uv_y * mask_scale.y) + mask_offset;
vec2 mask_uv_z = (uv_z * mask_scale.x) + mask_offset;

vec3 mask_sample_x = texture(texture_mask, mask_uv_x).rgb * weights.x;
vec3 mask_sample_y = texture(texture_mask, mask_uv_y).rgb * weights.y;
vec3 mask_sample_z = texture(texture_mask, mask_uv_z).rgb * weights.z;
vec3 mask_final = mask_sample_x + mask_sample_y + mask_sample_z;

/* STREAMING_CHUNK:Sampling Texture B conditionally... */
vec3 target_color_b = color_b;
if (use_texture_b) {
	vec2 b_uv_x = (uv_x * texture_b_scale) + texture_b_offset;
	vec2 b_uv_y = (uv_y * texture_b_scale) + texture_b_offset;
	vec2 b_uv_z = (uv_z * texture_b_scale) + texture_b_offset;
	
	vec3 b_sample_x = texture(texture_b, b_uv_x).rgb * weights.x;
	vec3 b_sample_y = texture(texture_b, b_uv_y).rgb * weights.y;
	vec3 b_sample_z = texture(texture_b, b_uv_z).rgb * weights.z;
	vec3 texture_b_final = b_sample_x + b_sample_y + b_sample_z;
	
	target_color_b = texture_b_final * color_b;
}

/* STREAMING_CHUNK:Blending colors and setting output ALBEDO... */
vec3 mask_blended = mix(vec3(1.0), mask_final, blend_amount);

if (use_uv_mapping) {
		// use the mesh's UVs instead of the world-space projection
		ALBEDO = color_b * texture(texture_b, UV).rgb;
	} else {
		ALBEDO = mix(color_a, target_color_b, mask_blended);
	}
}

void light() {
	if (LIGHT_IS_DIRECTIONAL) {
		// ray from the surface toward the sun, in world space
		vec3 ray_dir = mat3(world_mat) * LIGHT;
		// where that ray crosses the cloud layer
		float t = (cloud_height - world_pos.y) / ray_dir.y;
		vec3 P = world_pos + t * ray_dir;

		vec2 uv_offset = vec2(TIME) * cloud_speed;
		vec4 rg = textureLod(cloud_noise, P.xz * cloud_scale + uv_offset, cloud_mip);

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
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
}
