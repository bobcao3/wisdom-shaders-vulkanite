struct EncodedVertex {
    half4 position;
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
        const half div = half(1.0 / 255.0);
        half4 c0 = half4(vertices[0].color) * div;
        half4 c1 = half4(isSideA ? vertices[1].color : vertices[2].color) * div;
        half4 c2 = half4(isSideA ? vertices[2].color : vertices[3].color) * div;
        return c0 * baryCoords.x + c1 * baryCoords.y + c2 * baryCoords.z;
    }

    float3 getPositionLocal(float3 baryCoords, bool isSideA) {
        float3 p0 = vertices[0].position.xyz;
        float3 p1 = (isSideA ? vertices[1].position.xyz : vertices[2].position.xyz);
        float3 p2 = (isSideA ? vertices[2].position.xyz : vertices[3].position.xyz);
        return p0 * baryCoords.x + p1 * baryCoords.y + p2 * baryCoords.z;
    }

    float3 getPositionLocal(float2 baryCoords, uint primitiveIndex) {
        bool isSideA = (primitiveIndex & 1) == 0;
        float3 barys = float3(1.0 - baryCoords.x - baryCoords.y, baryCoords.x, baryCoords.y);
        return getPositionLocal(barys, isSideA);
    }

    float2 getFragmentUV(float3 baryCoords, bool isSideA) {
        float2 t0 = (vertices[0].block_texture) / 65536.0;
        float2 t1 = (isSideA ? vertices[1].block_texture : vertices[2].block_texture) / 65536.0;
        float2 t2 = (isSideA ? vertices[2].block_texture : vertices[3].block_texture) / 65536.0;
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
