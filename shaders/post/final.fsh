#version 430

//#ifndef VULKANITE
//#include "/lib/no_vulkanite.glsl"
//#elif

#include "/lib/tonemap.glsl"

in vec2 texCoord;

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform sampler2D colortex3;

uniform sampler2D colortex9;
uniform sampler2D depthtex0;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 fragColor;

uniform float near;
uniform float far;

uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelViewInverse;

float linearizeDepth(float depth, float near, float far) {
    return (near * far) / (depth * (near - far) + far);
}

void main() {
    fragColor = texture(colortex0, texCoord);
    fragColor.rgb = ACESFilm(fragColor.rgb);
    fragColor.rgb = pow(fragColor.rgb, vec3(1.0 / 2.2));

    // Composite with non-RT image
    float depth = texture(depthtex0, texCoord).r;
    vec4 projPos = vec4(texCoord * 2.0 - 1.0, depth * 2.0 - 1.0, 1.0);
    vec4 viewPos = gbufferProjectionInverse * projPos;
    viewPos /= viewPos.w;

    vec4 worldPos = gbufferModelViewInverse * viewPos;
    float dist = length(viewPos.xyz);

    float rtDist = texture(colortex3, texCoord).r;

    rtDist = min(rtDist, textureOffset(colortex3, texCoord, ivec2(-1, -1)).r);
    rtDist = min(rtDist, textureOffset(colortex3, texCoord, ivec2(-1, 0)).r);
    rtDist = min(rtDist, textureOffset(colortex3, texCoord, ivec2(-1, 1)).r);
    rtDist = min(rtDist, textureOffset(colortex3, texCoord, ivec2(0, -1)).r);
    rtDist = min(rtDist, textureOffset(colortex3, texCoord, ivec2(0, 1)).r);
    rtDist = min(rtDist, textureOffset(colortex3, texCoord, ivec2(1, -1)).r);
    rtDist = min(rtDist, textureOffset(colortex3, texCoord, ivec2(1, 0)).r);
    rtDist = min(rtDist, textureOffset(colortex3, texCoord, ivec2(1, 1)).r);

    if (rtDist > dist * 1.01) {
        fragColor.rgb = texture(colortex9, texCoord).rgb;
    }

    // fragColor.rgb = vec3(1.0 / rtDist);
}

//#endif