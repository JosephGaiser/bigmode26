shader_type canvas_item;

uniform vec4 color_dark : source_color = vec4(0, 0, 0, 1);
uniform vec4 color_light : source_color = vec4(1, 1, 1, 1);
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, repeat_disable, filter_nearest;

void fragment() {
    vec4 pixel = texture(SCREEN_TEXTURE, SCREEN_UV);
    COLOR = pixel.r == 1.0 ? color_light : color_dark;
}