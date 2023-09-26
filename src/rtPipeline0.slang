import bindings;
import scene.scene;
import math;
import payload;
import random.random;
import random.hybridTaus;
import random.halton;
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

    let blueNoise3D = gBlueNoise.Load(int4(launchIndex & int2(127, 127), gCameraInfo.frameId & 63, 0)).rgb;
    let seed = uint4(uint3(blueNoise3D * 65536), gCameraInfo.frameId * 21157 + launchIndex.x * 1973 + launchIndex.y * 1013);
    var rng = HybridTausGenerator(seed);
    // var rng = HaltonRNG((uint3(blueNoise3D) << 16) + gCameraInfo.frameId * 256);

    const float2 pixelPos = float2(launchIndex) + rng.nextRand2D();
    const float2 screenPos = pixelPos / float2(DispatchRaysDimensions().xy);
    const float3 origin = transpose(gCameraInfo.viewInverse)[3].xyz;
    const float3 target = lerp(lerp(gCameraInfo.corners[0], gCameraInfo.corners[2], screenPos.y), lerp(gCameraInfo.corners[1], gCameraInfo.corners[3], screenPos.y), screenPos.x);
    const float3 direction = mul(gCameraInfo.viewInverse, float4(normalize(target.xyz), 0.0)).xyz;

    var pt = BasicPathTracer<PBRMinecraftScene>(float3(1.0), origin, direction);
    pt.setScene(PBRMinecraftScene());

    // var pt = BasicPathTracer<VanillaMinecraftWorld>(float3(1.0), origin, direction);
    // pt.setScene(VanillaMinecraftWorld());

    // var pt = BasicPathTracer<LambertGrayWorld>(float3(1.0), origin, direction);
    // pt.setScene(LambertGrayWorld(float3(0.5)));

    for (int i = 0; i < 4; i++) {
        if (!pt.nextPathSegment(rng)) {
            break;
        }
        if (i > 0) {
            // Russian roulette
            float3 t = pt.getCurrentThroughput();
            float p = max(t.x, max(t.y, t.z));

            if (rng.nextRand() > p) {
                break;
            } else {
                pt.adjustThroughput(float3(1.0 / p));
            }
        }
    }

    float3 color = pt.integratePath();

    // Debug
    if (false) {
        RayDesc ray;
        ray.Origin = origin;
        ray.Direction = direction;
        ray.TMin = 0.0f;
        ray.TMax = 100000.0f;

        MaterialRayPayload payload = traceMaterialRay(ray);

        let hitQuad = gGeometries.getQuad(payload.geometryIndex, payload.primitiveIndex);
        let hitFragInfo = hitQuad.getFragmentInfo(payload.barycentrics, payload.primitiveIndex);

        let normalData = gBlockAtlasNormal.Sample(hitFragInfo.uv);
        let specularData = gBlockAtlasSpecular.Sample(hitFragInfo.uv);

        let lightLevel = hitFragInfo.lightUV.r;
        color = float3(step(50.0, lightLevel), step(240.0, lightLevel), step(254.0, lightLevel));
    }

    gOutImage[launchIndex] = float4(color, 1.0);
}
