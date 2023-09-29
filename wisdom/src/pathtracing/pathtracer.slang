import bsdf;
import random.random;
import random.weightedRIS;
import math;
import scene.scene;

interface IPathTracer {
    associatedtype Scene : IScene;

    // Setup the pathtracer
    __init(float3 initialThroughput, float3 position, float3 direction, Scene scene);

    // Returns the current throughput of the path
    float3 getCurrentThroughput();

    // Adjusts the throughput of the path (e.g. for russian roulette)
    [[mutating]]
    void adjustThroughput(float3 adjustment);

    // Returns current ray depth
    uint getCurrentDepth();

    // Integrates the whole path, returns radiance
    [[mutating]]
    float3 integratePath();

    // Advances the pathtracer to the next path segment.
    // Returns false if the path has terminated.
    [[mutating]]
    bool nextPathSegment<RngT : IRandomNumberGenerator>(inout RngT rng);
}

import payload;
import bindings;

struct BasicPathTracer<_Scene : IScene> : IPathTracer {
    uint depth;
    float3 throughput;
    float3 position;
    float3 direction;
    float3 contribution;

    typedef _Scene Scene;

    Scene scene;

    __init(float3 initialThroughput, float3 position, float3 direction, Scene scene) {
        depth = 0;
        throughput = initialThroughput;
        contribution = float3(0.0f);
        this.position = position;
        this.direction = direction;
        this.scene = scene;
    }

    float3 getCurrentThroughput() {
        return throughput;
    }

    [[mutating]]
    void adjustThroughput(float3 adjustment) {
        throughput *= adjustment;
    }

    uint getCurrentDepth() {
        return depth;
    }

    MaterialRayPayload traceMaterialRay(in RayDesc ray) {
        MaterialRayPayload primaryPayload = getMaterialRayPayload();

        const uint rayFlags = RAY_FLAG_CULL_BACK_FACING_TRIANGLES;
        TraceRay(gAccelerationStructure, rayFlags, 0xFF, 0, 0, 0, ray, primaryPayload);

        return primaryPayload;
    }

    bool traceVisibilityRay(in RayDesc ray) {
        MaterialRayPayload payload = getShadowRayPayload();

        const uint rayFlags = RAY_FLAG_CULL_BACK_FACING_TRIANGLES | RAY_FLAG_SKIP_CLOSEST_HIT_SHADER | RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH;
        TraceRay(gAccelerationStructure, rayFlags, 0xFF, 0, 0, 0, ray, payload);

        return payload.hitT > 0.0;
    }

    [[mutating]]
    float3 integratePath() {
        return contribution;
    }

    [[mutating]]
    bool nextPathSegment<RngT : IRandomNumberGenerator>(inout RngT rng) {
        RayDesc ray;
        ray.Origin = position;
        ray.Direction = direction;
        ray.TMin = 0.0f;
        ray.TMax = 100000.0f;
        
        MaterialRayPayload payload = traceMaterialRay(ray);

        if (payload.hitT < 0.0) {
            contribution += throughput * scene.getDomeRadiance(direction);

            // Miss
            return false;
        }

        // Hit
        // const bool useGeomPosition = distance(payload.wldPos, position) < (payload.hitT + payload.wldErrOffset * 2);
        // precise let hitPosition = useGeomPosition ? payload.wldPos : (position + direction * payload.hitT);
        precise let hitPosition = payload.wldPos;
        precise let hitGeomNormal = payload.wldNormal;
        precise let hitGeomError = payload.wldErrOffset;

        float3 hitMaterialNormal;
        float3 hitMaterialEmission;
        let hitMaterial = scene.getHitMaterial(payload, hitMaterialNormal, hitMaterialEmission);

        position = mad(hitGeomError, hitGeomNormal, hitPosition);
        let wo = -direction;

        // Add contribution of this vertex
        // Importance sample directional light using WRIS
        if (scene.getNDirLights() > 0) {
            float3 lightBsdf;
            float3 lightRadiance;
            float3 lightWi;

            WeightedReservior R;
            for (int i = 0; i < scene.getNDirLights(); i++) {
                let light = scene.getDirLight(i);
                float3 sampledWi;
                let sampledRadiance = light.sample(rng, position, sampledWi);
                let sampledBsdf = hitMaterial.evaluate(hitMaterialNormal, hitGeomNormal, sampledWi, wo);
                let weight = luminance(sampledBsdf * sampledRadiance);

                if (R.add(rng, weight)) {
                    lightWi = sampledWi;
                    lightBsdf = sampledBsdf;
                    lightRadiance = sampledRadiance;
                }
            }

            // Check visibility
            RayDesc shadowRay;
            shadowRay.Origin = position;
            shadowRay.Direction = lightWi;
            shadowRay.TMin = 0.0;
            shadowRay.TMax = 100000.0f;
            bool shadowed = traceVisibilityRay(shadowRay);

            if (!shadowed) {
                contribution += max(nanToZero(throughput * lightBsdf * lightRadiance / R.getProb()), 0.0);
            }
        }
        // Emissive
        contribution += throughput * hitMaterialEmission;

        // Sample BSDF for next direction
        float bsdfSamplePdf;
        float3 wi;
        hitMaterial.sample(rng, hitMaterialNormal, hitGeomNormal, wo, bsdfSamplePdf, wi);
        direction = wi;

        // Update throughput for next vertex
        throughput = max(nanToZero(throughput * hitMaterial.evaluate(hitMaterialNormal, hitGeomNormal, wi, wo) / bsdfSamplePdf), 0.0);

        return true;
    }
}
