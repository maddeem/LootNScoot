shader_type canvas_item;
render_mode blend_add;

uniform float tileScale = 0.1;
uniform float speed = 0.1;
varying float object_scale_x;

// Parameters for multiple sine waves
uniform float wave1_amplitude = 0.04;
uniform float wave1_frequency = 4.0;
uniform float wave1_speed = 0.8;

uniform float wave2_amplitude = 0.02;
uniform float wave2_frequency = 7.0;
uniform float wave2_speed = 1.2;

uniform float wave3_amplitude = 0.01;
uniform float wave3_frequency = 10.0;
uniform float wave3_speed = 0.5;

uniform float dampening_strength = 2.0; // Controls how fast the waves dampen at the edges. Higher = stronger dampening.
uniform float dampening_power = 2.0;    // Controls the curve of the dampening. 1.0 is linear, 2.0 is quadratic, etc.

uniform vec4 modulate : source_color;

void vertex() {
    // Calculate X scale from the MODEL_MATRIX
    vec2 scale_x = vec2(MODEL_MATRIX[0].x, MODEL_MATRIX[1].x);
    object_scale_x = length(scale_x);
}

void fragment() {
    vec2 uv = UV;

    // Calculate the dampening factor
    // This creates a falloff that is 0 at UV.x = 0 and UV.x = 1, and peaks at UV.x = 0.5
    float dampening_factor = uv.x * (1.0 - uv.x);

    // You can adjust the dampening curve and strength
    dampening_factor = pow(dampening_factor * dampening_strength, dampening_power);

    // Clamp the factor to prevent overshooting, though with typical settings it might not be necessary
    dampening_factor = clamp(dampening_factor, 0.0, 1.0);

    // Combine multiple sine waves for more chaotic distortion
    float combined_wave_offset = 0.0;
    combined_wave_offset += sin(uv.x * wave1_frequency * object_scale_x + TIME * wave1_speed) * wave1_amplitude;
    combined_wave_offset += sin(uv.x * wave2_frequency * object_scale_x + TIME * wave2_speed) * wave2_amplitude;
    combined_wave_offset += sin(uv.x * wave3_frequency * object_scale_x + TIME * wave3_speed) * wave3_amplitude;

    // Apply the dampening factor to the wave offset
    uv.y += combined_wave_offset * dampening_factor;

    uv.x *= object_scale_x * tileScale;
    uv.x += TIME * speed;

    vec4 color = texture(TEXTURE, uv);
    float brightness = max(color.r, max(color.g, color.b));
    color.a = brightness;
    COLOR = color * modulate;
}