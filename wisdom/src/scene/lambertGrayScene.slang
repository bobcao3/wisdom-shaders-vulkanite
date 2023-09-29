import payload;
import scene.scene;
import pathtracing.light;
import pathtracing.bsdf;

struct LambertGrayWorld : IScene {
    typedef LambertianBSDF BSDF;

    float3 albedo;

    __init(float3 albedo) {
        this.albedo = albedo;
    }

    int getNDirLights() {
        return 0;
    }

    DirectionalLight getDirLight(int id) {
        return DirectionalLight(float3(0.0), float3(0.0), 0.0);
    }

    float3 getDomeRadiance(float3 dir) {
        return float3(1.0);
    }

    BSDF getHitMaterial(MaterialRayPayload payload, out float3 shadingNormal, out float3 emission) {
        shadingNormal = payload.wldNormal;
        emission = float3(0.0);
        return LambertianBSDF(albedo);
    }
}
