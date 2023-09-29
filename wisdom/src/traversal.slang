import bindings;
import scene.geomData;
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

    let quad = gGeometries.getQuad(InstanceID() + GeometryIndex(), PrimitiveIndex());
    precise float3 v0, v1, v2;
    quad.getPositions(PrimitiveIndex(), v0, v1, v2);

    precise float2 barys = attr.barycentrics;

    precise float3 edge1 = v1 - v0;
    precise float3 edge2 = v2 - v0;
    // interpolate triangle using barycentrics
    // add in base vertex last to reduce object-space error
    precise float3 objPosition = v0 + mad(barys.x, edge1, mul(barys.y, edge2));
    float3 objNormal = cross(edge1, edge2);

    const float3x4 o2w = ObjectToWorld3x4();

    // transform object-space position
    // add in translation last to reduce world-space error
    precise float3 wldPosition;
    wldPosition.x = o2w._m03 +
                    mad(o2w._m00, objPosition.x,
                        mad(o2w._m01, objPosition.y,
                            mul(o2w._m02, objPosition.z)));
    wldPosition.y = o2w._m13 +
                    mad(o2w._m10, objPosition.x,
                        mad(o2w._m11, objPosition.y,
                            mul(o2w._m12, objPosition.z)));
    wldPosition.z = o2w._m23 +
                    mad(o2w._m20, objPosition.x,
                        mad(o2w._m21, objPosition.y,
                            mul(o2w._m22, objPosition.z)));

    const float3x4 w2o = WorldToObject3x4();

    // transform normal to world-space using
    // inverse transpose matrix
    float3 wldNormal = mul(transpose((float3x3)w2o), objNormal);

    // normalize world-space normal
    const float wldScale = rsqrt(dot(wldNormal, wldNormal));
    wldNormal = mul(wldScale, wldNormal);

    // flip towards incoming ray
    if (dot(WorldRayDirection(), wldNormal) > 0)
        wldNormal = -wldNormal;

    payload.wldPos = wldPosition;
    payload.wldNormal = wldNormal;

    // Error bounds magic number
    // https://developer.nvidia.com/blog/solving-self-intersection-artifacts-in-directx-raytracing/
    const float c0 = 5.9604644775390625E-8f;
    const float c1 = 1.788139769587360206060111522674560546875E-7f;

    // compute twice the maximum extent of the triangle
    const float3 extent3 = abs(edge1) + abs(edge2) +
                           abs(abs(edge1) - abs(edge2));
    const float extent = max(max(extent3.x, extent3.y), extent3.z);

    // bound object-space error due to reconstruction and intersection
    float3 objErr = mad(c0, abs(v0), mul(c1, extent));

    // bound world-space error due to object-to-world transform
    const float c2 = 1.19209317972490680404007434844970703125E-7f;
    float3 wldErr = mad(c1, mul(abs((float3x3)o2w), abs(objPosition)),
                        mul(c2, abs(transpose(o2w)[3])));

    // bound object-space error due to world-to-object transform
    objErr = mad(c2, mul(abs(w2o), float4(abs(wldPosition), 1)), objErr);

    // compute world-space self-intersection avoidance offset
    float objOffset = dot(objErr, abs(objNormal));
    float wldOffset = dot(wldErr, abs(wldNormal));
    wldOffset = mad(wldScale, objOffset, wldOffset);

    payload.wldErrOffset = wldOffset;
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
