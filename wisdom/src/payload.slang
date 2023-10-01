import encoding;

struct MaterialRayPayload {
    float3 wldPos;
    float hitT;
    float wldErrOffset;
    uint geometryIndex;
    uint primitiveIndex;
    half2 barycentrics;

    uint16_t2 encodedNormals;
    property wldNormal : float3 {
        get { return octahedronDecode(float2(encodedNormals) / 65535.0); }
        set { encodedNormals = uint16_t2(octahedronEncode(newValue) * 65535.0); }
    }
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
