bool is_inside_usquare(vec2 x) {
	return x == clamp(x, vec2(0.0), vec2(1.0));
}

vec4 blend(vec4 bottom, vec4 top) {
    float alpha = top.a + bottom.a * (1.0 - top.a);
    if (alpha < 0.0001) return vec4(0.0);
    vec3 color = mix(bottom.rgb * bottom.a, top.rgb, top.a) / alpha;
    return vec4(color, alpha);
}

vec4 apply_outline(sampler2D txtr, vec2 uv, float outline_thickness, vec2 pixel_size, vec4 outline_color, vec4 color) {
	float alpha = 0.0;
	vec4 texture_color = texture(txtr, uv);
	for (float y = 1.0; y <= outline_thickness; y++) {
		for (float x = 0.0; x <= y; x++) {
			if (length(vec2(x, y - 0.5)) > outline_thickness) break;
			float look_at_alpha;
			vec2 look_at_uv[8] = {
				uv + vec2(x, y) * pixel_size,
				uv + vec2(-x, y) * pixel_size,
				uv + vec2(x, -y) * pixel_size,
				uv + vec2(-x, -y) * pixel_size,
				uv + vec2(y, x) * pixel_size,
				uv + vec2(-y, x) * pixel_size,
				uv + vec2(y, -x) * pixel_size,
				uv + vec2(-y, -x) * pixel_size
			};
			for (int i = 0; i < 8; i++) {
				if (is_inside_usquare(look_at_uv[i])) {
					look_at_alpha = texture(txtr, look_at_uv[i]).a;
					if (look_at_alpha > alpha) alpha =
						look_at_alpha;
						if (1.0 - alpha < 0.0001)
							break; // Optimization: if alpha is already near 1, stop
						}
					}
			if (1.0 - alpha < 0.0001)
				break; // Optimization: if alpha is already near 1, stop
			}
		if (1.0 - alpha < 0.0001)
			break; // Optimization: if alpha is already near 1, stop
		}
	vec4 base_color = blend(vec4(outline_color.rgb, alpha * outline_color.a), texture_color);
	return mix(base_color, color, color.a);
}