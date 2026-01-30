shader_type canvas_item;

uniform float lookup_size = 64.0;
uniform float error_carry = 0.3;
uniform float dither_threshold = 0.5;
uniform vec3 luminance_weights = vec3(0.2126, 0.7152, 0.0722);

uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_nearest;

float getGrayscale(vec2 coords, vec2 iResolution){
    vec2 uv = coords / iResolution.xy;
    vec3 sourcePixel = texture(screen_texture, uv).rgb;
    return dot(sourcePixel, luminance_weights);
}
	
void fragment() {
    vec2 iResolution = 1.0 / SCREEN_PIXEL_SIZE;
    
    float xError = 0.0;
    for(float xLook=0.0; xLook<lookup_size; xLook++){
        float grayscale = getGrayscale(FRAGCOORD.xy + vec2(-lookup_size+xLook,0),iResolution);
        grayscale += xError;
        float bit = grayscale >= dither_threshold ? 1.0 : 0.0;
        xError = (grayscale - bit)*error_carry;
    }
    
    float yError = 0.0;
    for(float yLook=0.0; yLook<lookup_size; yLook++){
        float grayscale = getGrayscale(FRAGCOORD.xy + vec2(0,-lookup_size+yLook),iResolution);
        grayscale += yError;
        float bit = grayscale >= dither_threshold ? 1.0 : 0.0;
        yError = (grayscale - bit)*error_carry;
    }
    
    float finalGrayscale = getGrayscale(FRAGCOORD.xy,iResolution);
    finalGrayscale += xError*0.5 + yError*0.5;
    float finalBit = finalGrayscale >= dither_threshold ? 1.0 : 0.0;
    
    COLOR = vec4(finalBit,finalBit,finalBit,1);
}