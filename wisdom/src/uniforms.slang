struct CameraInfo {
    float3 corners[4];
    float4x4 viewInverse;
    float4 sunPosition;
    float4 moonPosition;
    uint frameId;
    uint flags;
};
