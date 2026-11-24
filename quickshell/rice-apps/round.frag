#version 440
// A picture with round corners, cropped to fill its box (the DarkShadow apps' thumbnails):
// no extra layer per picture, the corners are cut while it is drawn.
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec2 box;
    float radius;
    vec2 sc;
    vec2 off;
};
layout(binding = 1) uniform sampler2D source;
void main() {
    vec2 p = qt_TexCoord0 * box;
    vec2 h = box * 0.5;
    vec2 q = abs(p - h) - (h - vec2(radius));
    float d = length(max(q, 0.0)) + min(max(q.x, q.y), 0.0) - radius;
    float a = 1.0 - smoothstep(-0.7, 0.7, d);
    fragColor = texture(source, off + qt_TexCoord0 * sc) * a * qt_Opacity;
}
