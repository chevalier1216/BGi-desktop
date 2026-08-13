shader_type canvas_item;

uniform sampler2D gold_texture : source_color;

void fragment() {
	vec4 mask_color = texture(TEXTURE, UV);
	vec3 gold_color = texture(gold_texture, UV).rgb;
	COLOR = vec4(gold_color, mask_color.a);
}
