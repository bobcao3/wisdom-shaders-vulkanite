import uniforms;
import scene.geomData;

[[vk::binding(0)]]
ConstantBuffer<CameraInfo> gCameraInfo;

[[vk::binding(1)]]
RaytracingAccelerationStructure gAccelerationStructure;

[[vk::binding(3)]]
Sampler2D gBlockAtlas;

[[vk::binding(4)]]
Sampler2D gBlockAtlasNormal;

[[vk::binding(5)]]
Sampler2D gBlockAtlasSpecular;

[[vk::binding(6)]]
RWTexture2D gOutImage[16];

[[vk::binding(0, 1)]]
struct Geometries {
    ByteAddressBuffer gQuadBuffers[];

    EncodedQuad getQuad(uint sectionIndex, uint primId) {
        uint address = (primId >> 1) * sizeof(EncodedQuad);
        return gQuadBuffers[NonUniformResourceIndex(sectionIndex)].Load<EncodedQuad>(address);
    }

    EncodedQuadEntities getEntityQuad(uint sectionIndex, uint primId) {
        uint address = (primId >> 1) * sizeof(EncodedQuadEntities);
        return gQuadBuffers[NonUniformResourceIndex(sectionIndex)].Load<EncodedQuadEntities>(address);
    }
} gGeometries;

[[vk::binding(0, 2)]]
Sampler3D gBlueNoise;
