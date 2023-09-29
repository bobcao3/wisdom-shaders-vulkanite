import payload;
import bindings;
import math;
import scene.scene;
import pathtracing.light;
import pathtracing.bsdf;

struct PBRMinecraftScene : IScene {
    typedef NormalFlipBSDF<MixBSDF<GGXSchlickBSDF, DisneyDiffuseBSDf>> BSDF;

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
        let hitQuad = gGeometries.getQuad(payload.geometryIndex, payload.primitiveIndex);
        let hitFragInfo = hitQuad.getFragmentInfo(payload.barycentrics, payload.primitiveIndex);
        let albedo = hitFragInfo.color.xyz * gBlockAtlas.Sample(hitFragInfo.uv).xyz;
        let specularData = gBlockAtlasSpecular.Sample(hitFragInfo.uv);
        let emmisivityFactor = specularData.w == 1.0 ? 0.0 : specularData.w * (255.0f / 254.0f);

        let normalStrength = 0.5;
        let t2w = float3x3(hitFragInfo.tangent, hitFragInfo.bitangent, hitFragInfo.normal);
        let normalTexData = gBlockAtlasNormal.Sample(hitFragInfo.uv);
        let hitMaterialNormal = normalize(lerp(hitFragInfo.normal, mul(mad(normalTexData.xyz, 2.0, -1.0), t2w), normalStrength));

        let roughness = pow(1.0 - specularData.x, 2.0);
        let f0 = float3(specularData.y);
        let metalness = specularData.y > (229.0 / 255.0) ? 1.0 : 0.0;
        let specular = specularData.y >= 0.04 ? 1.0 : 0.0;
        let hitMaterial = NormalFlipBSDF<MixBSDF<GGXSchlickBSDF, DisneyDiffuseBSDf>>(
            MixBSDF<GGXSchlickBSDF, DisneyDiffuseBSDf>(
                specular,
                GGXSchlickBSDF(albedo, f0, roughness),
                DisneyDiffuseBSDf(albedo, roughness)
            )
        );

        shadingNormal = hitMaterialNormal;
        emission = albedo * emmisivityFactor;
        return hitMaterial;
    }
};
