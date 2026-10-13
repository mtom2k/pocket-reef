shader_type canvas_item;
// Swim wobble (docs/style-guide.md section 8): pixel columns bob vertically, more toward the tail.
// Sprites face right, so the tail is at UV.x = 0. Texture needs vertical padding (see SpeciesDB.padded_texture).

uniform float phase = 0.0;
uniform float amplitude = 1.2;  // texels at the tail tip
uniform float waves = 0.35;     // phase step per column

varying vec4 tint;  // modulate; fragment COLOR already includes the texture, so keep tint separately

void vertex() {
	tint = COLOR;
}

void fragment() {
	vec2 size = 1.0 / TEXTURE_PIXEL_SIZE;
	float col = floor(UV.x * size.x);
	float tail = pow(1.0 - col / size.x, 1.6);
	float dy = floor(amplitude * tail * sin(phase - col * waves) + 0.5);
	vec2 uv = UV - vec2(0.0, dy * TEXTURE_PIXEL_SIZE.y);
	COLOR = tint * ((uv.y < 0.0 || uv.y > 1.0) ? vec4(0.0) : texture(TEXTURE, uv));
}
