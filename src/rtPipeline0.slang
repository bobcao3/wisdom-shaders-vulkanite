import bindings;
import sceneData;
import payload;
import random.random;
import random.hybridTaus;
import pathtracing.pathtracer;

MaterialRayPayload traceMaterialRay(in RayDesc ray) {
    MaterialRayPayload primaryPayload = getMaterialRayPayload();
    
    const uint rayFlags = RAY_FLAG_CULL_BACK_FACING_TRIANGLES;
    TraceRay(gAccelerationStructure, rayFlags, 0xFF, 0, 0, 0, ray, primaryPayload);

    return primaryPayload;
}

bool traceVisibilityRay(in RayDesc ray) {
    MaterialRayPayload payload = getShadowRayPayload();

    const uint rayFlags = RAY_FLAG_CULL_BACK_FACING_TRIANGLES | RAY_FLAG_SKIP_CLOSEST_HIT_SHADER | RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH;
    TraceRay(gAccelerationStructure, rayFlags, 0xFF, 0, 0, 0, ray, payload);

    return payload.hitT > 0.0;
}

[shader("raygeneration")]
void raygenMain() {
    const uint2 launchIndex = DispatchRaysIndex().xy;

    var rng = HybridTausGenerator(uint3(launchIndex, gCameraInfo.frameId) * 0x12345678);
    rng.nextRand();

    const float2 pixelPos = float2(launchIndex) + uniform2D(rng);
    const float2 screenPos = pixelPos / float2(DispatchRaysDimensions().xy);
    const float3 origin = transpose(gCameraInfo.viewInverse)[3].xyz;
    const float3 target = lerp(lerp(gCameraInfo.corners[0], gCameraInfo.corners[2], screenPos.y), lerp(gCameraInfo.corners[1], gCameraInfo.corners[3], screenPos.y), screenPos.x);
    const float3 direction = mul(gCameraInfo.viewInverse, float4(normalize(target.xyz), 0.0)).xyz;

    var pt = BasicPathTracer(float3(1.0), origin, direction);
    pt.setSun(normalize(mul(float3x3(gCameraInfo.viewInverse), gCameraInfo.sunPosition.xyz)), float3(1.0));
    pt.setAmbient(float3(0.1));

    for (int i = 0; i < 4; i++) {
        if (!pt.nextPathSegment(rng)) {
            break;
        }
    }

    float3 color = pt.integratePath();

    gOutImage[launchIndex] = float4(color, 1.0);
}
