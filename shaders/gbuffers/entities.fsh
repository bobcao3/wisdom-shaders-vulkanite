#version 430

uniform sampler2D gtexture;
uniform sampler2D lightmap;

in vec2 texCoord;
in vec4 color;
in vec2 lightCoord;

/* RENDERTARGETS: 9 */
layout(location = 0) out vec4 fragColor;

void main() {
    fragColor = texture(gtexture, texCoord) * texture(lightmap, lightCoord) * color;
    if (fragColor.a < 0.1) {
        discard;
    }
}
