#version 430 compatibility

out vec2 texCoord;
out vec4 color;

void main() {
    gl_Position = ftransform();
    texCoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
    color = gl_Color;
}
