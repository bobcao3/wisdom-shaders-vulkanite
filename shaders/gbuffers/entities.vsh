#version 430 compatibility

out vec2 texCoord;
out vec4 color;
out vec2 lightCoord;

void main() {
    gl_Position = ftransform();

    color = gl_Color;
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    lightCoord = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
}
