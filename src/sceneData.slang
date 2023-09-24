struct EncodedVertex {
    uint16_t4 position;
    uint8_t4 color;
    uint16_t2 block_texture;
    uint16_t2 light_texture;
    uint16_t2 mid_tex_coord;
    int8_t4 tangent;
    int8_t3 normal;
    int8_t padA__;
    int16_t2 block_id;
    int8_t3 mid_block;
    int8_t padB__;
};

struct FragmentInfo {
    float2 uv;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    half4 color;
};

struct EncodedQuad {
    EncodedVertex vertices[4];

    half4 getFragmentColor(half3 baryCoords, bool isSideA) {
        let div = half(1.0 / 255.0);
        let c0 = half4(vertices[0].color) * div;
        let c1 = half4(vertices[isSideA ? 1 : 2].color) * div;
        let c2 = half4(vertices[isSideA ? 2 : 3].color) * div;
        return c0 * baryCoords.x + c1 * baryCoords.y + c2 * baryCoords.z;
    }

    void getPositions(uint primitiveIndex, out float3 v0, out float3 v1, out float3 v2) {
        let modelScale = 32.0 / 65536.0;
        let modelOffset = -8.0;
        let isSideA = (primitiveIndex & 1) == 0;
        v0 = mad(modelScale, float3(vertices[0].position.xyz), modelOffset);
        v1 = mad(modelScale, float3(vertices[isSideA ? 1 : 2].position.xyz), modelOffset);
        v2 = mad(modelScale, float3(vertices[isSideA ? 2 : 3].position.xyz), modelOffset);
    }

    float2 getFragmentUV(float3 baryCoords, bool isSideA) {
        float2 t0 = (vertices[0].block_texture) / 65536.0;
        float2 t1 = (vertices[isSideA ? 1 : 2].block_texture) / 65536.0;
        float2 t2 = (vertices[isSideA ? 2 : 3].block_texture) / 65536.0;
        return t0 * baryCoords.x + t1 * baryCoords.y + t2 * baryCoords.z;
    }

    float2 getFragmentUV(float2 baryCoords, uint primitiveIndex) {
        bool isSideA = (primitiveIndex & 1) == 0;
        float3 barys = float3(1.0 - baryCoords.x - baryCoords.y, baryCoords.x, baryCoords.y);
        return getFragmentUV(barys, isSideA);
    }

    FragmentInfo getFragmentInfo(float2 baryCoords, uint primitiveIndex) {
        bool isSideA = (primitiveIndex & 1) == 0;
        float3 barys = float3(1.0 - baryCoords.x - baryCoords.y, baryCoords.x, baryCoords.y);

        FragmentInfo info;
        info.uv = getFragmentUV(barys, isSideA);
        info.normal = vertices[0].normal / 128.0;
        info.tangent = vertices[0].tangent.xyz / 128.0;
        info.bitangent = cross(info.tangent, info.normal) * (vertices[0].tangent.w / 128.0);
        info.color = getFragmentColor(half3(barys), isSideA);
        return info;
    }
};
