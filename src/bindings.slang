import uniforms;
import sceneData;

[[vk::binding(0)]]
ConstantBuffer<CameraInfo> gCameraInfo;

[[vk::binding(1)]]
RaytracingAccelerationStructure gAccelerationStructure;

[[vk::binding(3)]]
RWTexture2D gOutImage;

[[vk::binding(4)]]
Sampler2D gBlockAtlas;

[[vk::binding(0, 1)]]
struct Geometries {
    RWStructuredBuffer<EncodedQuad> gQuadBuffers[];

    EncodedQuad getQuad(uint sectionIndex, uint primId) {
        return gQuadBuffers[NonUniformResourceIndex(sectionIndex)][primId >> 1];
    }
} gGeometries;
