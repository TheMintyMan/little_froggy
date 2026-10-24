shader_type spatial;
render_mode unshaded, cull_disabled;

uniform sampler2D noise_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec2 uv_scale = vec2(0.02);
uniform vec2 speed = vec2(0.01);
uniform float coverage = 0.45; // higher = more cloud, lower = less cloud
void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Blurrier mip level smooths the noise edges so the shadow edges crawl less
	float n = textureLod(noise_texture, UV * uv_scale + TIME * speed, 3.0).r;
	float cloud = smoothstep(coverage, coverage + 0.15, n);
	ALPHA = cloud;
	ALPHA_SCISSOR_THRESHOLD = 0.5; // makes the cutout edges hard so the shadow map keeps them
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the material.
//	// Uncomment to replace the default light processing function with this one.
//}
