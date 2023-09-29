#version 430 compatibility

uniform sampler2D gtexture;

in vec2 texCoord;
in vec4 color;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = texture(gtexture, texCoord) * color;
}
