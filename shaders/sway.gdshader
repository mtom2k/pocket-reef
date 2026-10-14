shader_type canvas_item;
// Plant sway: pixel rows shift sideways, more toward the tip. Texture needs horizontal padding.

uniform float amplitude = 2.0;  // texels at the tip
uniform float speed = 1.2;
uniform float seed = 0.0;
// Driven by the tank's clock (decor_layer.gd), not TIME: a TIME-animated shader would make
// Godot redraw every loop iteration in low-processor mode.
uniform float time = 0.0;

varying vec4 tint;  // modulate; fragment COLOR already includes the texture, so keep tint separately

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	float row = floor(UV.y * size.y);
	float tip = pow(1.0 - row / size.y, 1.5);
	float dx = floor(amplitude * tip * sin(time * speed + row * 0.12 + seed) + 0.5);
	vec2 uv = UV - vec2(dx * TEXTURE_PIXEL_SIZE.x, 0.0);
	COLOR = tint * ((uv.x < 0.0 || uv.x > 1.0) ? vec4(0.0) : texture(TEXTURE, uv));
}
