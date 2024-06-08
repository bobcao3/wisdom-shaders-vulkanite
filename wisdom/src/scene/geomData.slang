struct EncodedVertexTerrain {
    uint16_t4 position; // 0..8 bytes
    uint8_t4 color; // 8..12 bytes
    uint16_t2 block_texture; // 12..16 bytes
    uint16_t2 light_texture; // 16..20 bytes
    uint16_t2 mid_tex_coord; // 20..24 bytes
    int8_t4 tangent; // 24..28 bytes
    int8_t3 normal; // 28..31 bytes
    int8_t padA__; // 31..32 bytes
    int16_t2 block_id; // 32..36 bytes
    int8_t3 mid_block; // 36..39 bytes
    int8_t padB__; // 39..40 bytes
};

struct FragmentInfo {
    float2 uv;
    float3 normal;
    float3 tangent;
    float3 bitangent;
    half4 color;
    half2 lightUV;
};

struct EncodedQuad {
    EncodedVertexTerrain vertices[4];

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
        float2 t0 = (vertices[0].block_texture) / 32768.0;
        float2 t1 = (vertices[isSideA ? 1 : 2].block_texture) / 32768.0;
        float2 t2 = (vertices[isSideA ? 2 : 3].block_texture) / 32768.0;
        return t0 * baryCoords.x + t1 * baryCoords.y + t2 * baryCoords.z;
    }

    half2 getFragmentLightMap(half3 baryCoords, bool isSideA) {
        half div = half(1.0);// / 65536.0);
        half2 t0 = half2(vertices[0].light_texture) * div;
        half2 t1 = half2(vertices[isSideA ? 1 : 2].light_texture) * div;
        half2 t2 = half2(vertices[isSideA ? 2 : 3].light_texture) * div;
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
        info.lightUV = getFragmentLightMap(half3(barys), isSideA);
        return info;
    }
};

struct EncodedVertexEntity {
    float3 position;           // 0..12 bytes
    uint8_t4 color;            // 12..16 bytes
    float2 block_texture;      // 16..24 bytes
    uint16_t2 overlay_texture; // 24..28 bytes
    uint16_t2 light_texture;   // 28..32 bytes
    uint8_t3 normal;           // 32..35 bytes
    uint8_t1 padA__;           // 35..36 bytes
    uint16_t3 iris_entity;     // 36..42 bytes ???
    // float2 mid_tex_coord; // 42..50 bytes

    uint16_t padlol0; // 42..44 bytes
    uint16_t padlol1; // 44..46 bytes
    uint16_t padlol2; // 46..48 bytes
    uint16_t padlol3; // 48..50 bytes

    uint8_t4 tangent; // 50..54 bytes
    uint16_t padB__;  // 54..56 bytes
};

struct EncodedQuadEntities {
    EncodedVertexEntity vertices[4];

    half4 getFragmentColor(half3 baryCoords, bool isSideA) {
        let div = half(1.0 / 255.0);
        let c0 = half4(vertices[0].color) * div;
        let c1 = half4(vertices[isSideA ? 1 : 2].color) * div;
        let c2 = half4(vertices[isSideA ? 2 : 3].color) * div;
        return c0 * baryCoords.x + c1 * baryCoords.y + c2 * baryCoords.z;
    }

    void getPositions(uint primitiveIndex, out float3 v0, out float3 v1, out float3 v2) {
        // let modelScale = 32.0 / 65536.0;
        // let modelOffset = -8.0;
        let isSideA = (primitiveIndex & 1) == 0;
        // v0 = mad(modelScale, float3(vertices[0].position.xyz), modelOffset);
        // v1 = mad(modelScale, float3(vertices[isSideA ? 1 : 2].position.xyz), modelOffset);
        // v2 = mad(modelScale, float3(vertices[isSideA ? 2 : 3].position.xyz), modelOffset);
        v0 = vertices[0].position;
        v1 = vertices[isSideA ? 1 : 2].position;
        v2 = vertices[isSideA ? 2 : 3].position;
    }

    float2 getFragmentUV(float3 baryCoords, bool isSideA) {
        float2 t0 = vertices[0].block_texture;
        float2 t1 = vertices[isSideA ? 1 : 2].block_texture;
        float2 t2 = vertices[isSideA ? 2 : 3].block_texture;
        return t0 * baryCoords.x + t1 * baryCoords.y + t2 * baryCoords.z;
    }

    half2 getFragmentLightMap(half3 baryCoords, bool isSideA) {
        half2 t0 = half2(vertices[0].light_texture);
        half2 t1 = half2(vertices[isSideA ? 1 : 2].light_texture);
        half2 t2 = half2(vertices[isSideA ? 2 : 3].light_texture);
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
        info.lightUV = getFragmentLightMap(half3(barys), isSideA);
        return info;
    }
};
