import bindings;
import sceneData;
import payload;

[shader("miss")]
void missMain(inout MaterialRayPayload payload) {
    payload.hitT = -1.0;
}

[shader("closesthit")]
void closesthitMain(inout MaterialRayPayload payload, in BuiltInTriangleIntersectionAttributes attr) {
    payload.hitT = RayTCurrent();
    payload.geometryIndex = InstanceID() + GeometryIndex();
    payload.primitiveIndex = PrimitiveIndex();
    payload.barycentrics = half2(attr.barycentrics);
}

[shader("anyhit")]
void anyhitMain(inout MaterialRayPayload payload, in BuiltInTriangleIntersectionAttributes attr) {
    let quad = gGeometries.getQuad(InstanceID() + GeometryIndex(), PrimitiveIndex());
    let uv = quad.getFragmentUV(attr.barycentrics, PrimitiveIndex());
    float alpha = gBlockAtlas.Sample(uv).a;
    if (alpha < 0.05) {
        IgnoreHit();
    }
}

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

    const float2 pixelPos = float2(launchIndex) + 0.5;
    const float2 screenPos = pixelPos / float2(DispatchRaysDimensions().xy);
    const float3 origin = transpose(gCameraInfo.viewInverse)[3].xyz;
    const float3 target = lerp(lerp(gCameraInfo.corners[0], gCameraInfo.corners[2], screenPos.y), lerp(gCameraInfo.corners[1], gCameraInfo.corners[3], screenPos.y), screenPos.x);
    const float3 direction = mul(gCameraInfo.viewInverse, float4(normalize(target.xyz), 0.0)).xyz;

    RayDesc primaryRay;
    primaryRay.Origin = origin;
    primaryRay.Direction = direction;
    primaryRay.TMin = 0.0001;
    primaryRay.TMax = 4096.0;
    let primaryPayload = traceMaterialRay(primaryRay);

    float3 color = float3(0.0);

    if (primaryPayload.hitT > 0.0) {
        let quad = gGeometries.getQuad(primaryPayload.geometryIndex, primaryPayload.primitiveIndex);
        let fragInfo = quad.getFragmentInfo(primaryPayload.barycentrics, primaryPayload.primitiveIndex);
        float3 albedo = gBlockAtlas.Sample(fragInfo.uv).rgb * fragInfo.color.rgb;
        float3 hitPos = origin + direction * primaryPayload.hitT;

        let sunDir = normalize(gCameraInfo.sunPosition.xyz);
        RayDesc shadowRay;
        shadowRay.Origin = hitPos;
        shadowRay.Direction = sunDir;
        shadowRay.TMin = 0.0001;
        shadowRay.TMax = 4096.0;
        bool shadowed = traceVisibilityRay(shadowRay);

        color = shadowed ? albedo * 0.3 : albedo;
    } else {
        color = float3(0.5, 0.7, 1.0);
    }

    if (any(isnan(color))) {
        color = float3(1.0, 0.0, 1.0);
    }

    gOutImage[launchIndex] = float4(color, 1.0);
}
