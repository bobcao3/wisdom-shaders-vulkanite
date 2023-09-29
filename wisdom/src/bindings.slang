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
RWTexture2D gOutImage;

[[vk::binding(0, 1)]]
struct Geometries {
    RWStructuredBuffer<EncodedQuad> gQuadBuffers[];

    EncodedQuad getQuad(uint sectionIndex, uint primId) {
        return gQuadBuffers[NonUniformResourceIndex(sectionIndex)][primId >> 1];
    }
} gGeometries;

[[vk::binding(0, 2)]]
Sampler3D gBlueNoise;
