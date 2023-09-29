import geomData;
import payload;
import pathtracing.light;
import pathtracing.bsdf;
import math;
import bindings;

interface IScene {
    associatedtype BSDF : IBsdf;
    
    int getNDirLights();
    DirectionalLight getDirLight(int id);
    float3 getDomeRadiance(float3 dir);

    BSDF getHitMaterial(MaterialRayPayload payload, out float3 shadingNormal, out float3 emission);
};
