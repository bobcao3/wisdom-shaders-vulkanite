struct MaterialRayPayload {
    float hitT;
    float3 hitPos;
    uint geometryIndex;
    uint primitiveIndex;
    half2 barycentrics;
};

MaterialRayPayload getMaterialRayPayload() {
    MaterialRayPayload payload;
    payload.hitT = -1.0f;
    payload.geometryIndex = 0;
    payload.primitiveIndex = 0;
    payload.barycentrics = half2(0.0);
    return payload;
}

MaterialRayPayload getShadowRayPayload() {
    MaterialRayPayload payload;
    payload.hitT = 1.0f;
    return payload;
}
