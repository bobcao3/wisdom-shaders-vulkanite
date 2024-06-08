import payload;
import math;
import bindings;
import scene.scene;
import pathtracing.light;
import pathtracing.bsdf;

struct VanillaMinecraftScene : IScene {
    typedef LambertianBSDF BSDF;

    DirectionalLight sunLight;
    DirectionalLight moonLight;

    __init() {
        float3x3 viewInverse = float3x3(gCameraInfo.viewInverse);
        sunLight = DirectionalLight(
            normalize(mul(viewInverse, gCameraInfo.sunPosition.xyz)),
            float3(1.0),
            toRad(0.315)
        );
        moonLight = DirectionalLight(
            normalize(mul(viewInverse, gCameraInfo.moonPosition.xyz)),
            float3(0.01),
            toRad(0.35)
        );
    }

    int getNDirLights() {
        return 2;
    }

    DirectionalLight getDirLight(int id) {
        if (id == 0) {
            // Sun
            return sunLight;
        } else {
            // Moon
            return moonLight;
        }
    }

    float3 getDomeRadiance(float3 dir) {
        float sunHeight = sunLight.direction.y;
        float moonHeight = moonLight.direction.y;
        return float3(0.6, 0.7, 0.9) * (
            pow(saturate(sunHeight), 0.35) * 0.1 +
            pow(saturate(moonHeight), 0.35) * 0.001 +
            0.0001
        );
    }

    BSDF getHitMaterial(MaterialRayPayload payload, out float3 shadingNormal, out float3 emission) {
        if (payload.hitType == 1) {
            let hitQuad = gGeometries.getEntityQuad(payload.geometryIndex, payload.primitiveIndex);
            let hitFragInfo = hitQuad.getFragmentInfo(payload.barycentrics, payload.primitiveIndex);
            let albedo = hitFragInfo.color.xyz * float3(0.7);
            shadingNormal = payload.wldNormal;
            // emission = hitFragInfo.lightUV.r > 239.5 ? float3(albedo) : float3(0.0);
            emission = float3(0.0);
            return LambertianBSDF(albedo);
        }
        let hitQuad = gGeometries.getQuad(payload.geometryIndex, payload.primitiveIndex);
        let hitFragInfo = hitQuad.getFragmentInfo(payload.barycentrics, payload.primitiveIndex);
        let albedo = hitFragInfo.color.xyz * gBlockAtlas.Sample(hitFragInfo.uv).xyz;
        shadingNormal = payload.wldNormal;
        emission = hitFragInfo.lightUV.r > 239.5 ? float3(albedo) : float3(0.0);
        return LambertianBSDF(albedo);
    }
}
