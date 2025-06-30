shader_type canvas_item;

uniform float animation_time : hint_range(0.0, 1.0) = 0.0;

// Animation phases
uniform float slice_duration : hint_range(0.1, 0.8) = 0.3;
uniform float fade_duration : hint_range(0.1, 0.8) = 0.3;

// Slice parameters
uniform int slice_count : hint_range(3, 20) = 8;
uniform float slice_angle : hint_range(0.0, 6.28318530718) = 0.1;
uniform float slice_width : hint_range(0.001, 0.05) = 0.01;
uniform float slice_separation : hint_range(0.0, 1.0) = 0.2;
uniform float flash_intensity : hint_range(0.0, 3.0) = 1.5;
uniform vec4 slash_start_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);
uniform vec4 slash_end_color : source_color = vec4(1.0, 0.0, 0.0, 0.0);

float create_slashes(vec2 uv, float time_progress) {
    float slash_effect = 0.0;
    vec2 rotated_uv = mat2(vec2(cos(slice_angle), -sin(slice_angle)),
                          vec2(sin(slice_angle), cos(slice_angle))) * (uv - 0.5) + 0.5;
    for (int i = 0; i < slice_count; i++) {
        float slice_pos = float(i) / float(slice_count - 1);
        float slice_offset = slice_pos - 0.5;
        float slash_time = time_progress * 2.0 - slice_pos;
        slash_time = clamp(slash_time, 0.0, 1.0);
        float line_dist = abs(rotated_uv.y + slice_offset - 0.5);
        float slash_line = 1.0 - smoothstep(0.0, slice_width, line_dist);
        float glow = exp(-line_dist * 30.0) * 0.3;

        slash_effect += (slash_line + glow) * slash_time;
    }

    return clamp(slash_effect, 0.0, 1.0);
}

void fragment() {
	vec4 original_color = COLOR;
    vec4 final_color = original_color;
    float slice_end = slice_duration;
    float fade_start = slice_end * 0.8; // Start fade near end of slice
    float fade_end = fade_start + fade_duration;
    float slice_progress = (animation_time / slice_end) * 1.5;
    float fade_progress = clamp((animation_time - fade_start) / fade_duration, 0.0, 1.0);
    float slash_intensity = create_slashes(UV, slice_progress);
    vec4 current_slash_color = mix(slash_start_color * 5., slash_end_color, animation_time);
    vec3 slash_color = mix(original_color.rgb, current_slash_color.rgb, slash_intensity * flash_intensity);
    float slash_alpha = mix(original_color.a, current_slash_color.a * original_color.a, slash_intensity);
    float separation = slice_progress * slice_separation;
    vec2 separated_uv = UV;
    vec2 displacement_dir = vec2(cos(slice_angle + 1.57), sin(slice_angle + 1.57)); // Perpendicular to slashes

    for (int i = 0; i < slice_count; i++) {
        float slice_pos = float(i) / float(slice_count - 1) - 0.5;
        float slice_influence = exp(-abs((UV.y - 0.5) - slice_pos) * 20.0);
        separated_uv += displacement_dir * slice_influence * separation * float(i % 2 * 2 - 1) * 0.1;
    }
    vec4 separated_color = (texture(TEXTURE, separated_uv) * COLOR) * 2.0;
    final_color = vec4(mix(separated_color.rgb, slash_color, slash_intensity * 0.5),
                      mix(separated_color.a, slash_alpha, slash_intensity));
    final_color.a *= (1.0 - animation_time);

    COLOR = final_color;
}