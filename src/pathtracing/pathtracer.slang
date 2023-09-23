import bsdf;
import random.random;

interface IPathTracer {
    // Setup the pathtracer
    __init(float3 initialThroughput, float3 position, float3 direction);

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

struct BasicPathTracer : IPathTracer {
    uint depth;
    float3 throughput;
    float3 position;
    float3 direction;
    float3 contribution;

    float3 sunDirection;
    float3 sunRadiance;

    float3 ambientRadiance;

    __init(float3 initialThroughput, float3 position, float3 direction) {
        depth = 0;
        throughput = initialThroughput;
        this.position = position;
        this.direction = direction;
        contribution = float3(0.0f);

        this.sunDirection = float3(0.0, 1.0, 0.0);
        this.sunRadiance = float3(0.0);
        this.ambientRadiance = float3(0.0);
    }

    [[mutating]]
    void setSun(float3 sunDirection, float3 sunRadiance) {
        this.sunDirection = sunDirection;
        this.sunRadiance = sunRadiance;
    }

    [[mutating]]
    void setAmbient(float3 ambientRadiance) {
        this.ambientRadiance = ambientRadiance;
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
            contribution += throughput * ambientRadiance;

            // Miss
            return false;
        }

        // Hit
        precise let hitPosition = payload.wldPos;
        precise let hitGeomNormal = payload.wldNormal;
        precise let hitGeomError = payload.wldErrOffset;

        let hitQuad = gGeometries.getQuad(payload.geometryIndex, payload.primitiveIndex);
        let hitFragInfo = hitQuad.getFragmentInfo(payload.barycentrics, payload.primitiveIndex);
        let albedo = hitFragInfo.color.xyz * gBlockAtlas.Sample(hitFragInfo.uv).xyz;
        let specularData = gBlockAtlasSpecular.Sample(hitFragInfo.uv);
        let emmisivityFactor = specularData.w == 1.0 ? 0.0 : specularData.w * (255.0f / 254.0f);

        let hitMaterial = LambertianBSDF(albedo);

        // Sample BSDF
        float bsdfSamplePdf;
        float3 wi;
        let bsdfSample = hitMaterial.sample(rng, hitFragInfo.normal, direction, bsdfSamplePdf, wi);
        let wo = -direction;

        // Update throughput
        throughput *= bsdfSample; // Importance sampled. No need to divide by pdf.

        // Update contribution
        {
            // Sunlight
            RayDesc shadowRay;
            shadowRay.Origin = mad(hitGeomError, hitGeomNormal, hitPosition);
            shadowRay.Direction = sunDirection;
            shadowRay.TMin = 0.0;
            shadowRay.TMax = 100000.0f;
            bool shadowed = traceVisibilityRay(shadowRay);

            if (!shadowed) {
                let bsdfEval = hitMaterial.evaluate(hitFragInfo.normal, wo, sunDirection);
                let NdotL = abs(dot(hitFragInfo.normal, sunDirection));
                contribution += throughput * sunRadiance * bsdfEval * NdotL;
            }
        }
        if (emmisivityFactor > 0.0) {
            // Emissive
            contribution += throughput * emmisivityFactor * albedo;
        }

        // Update path state
        position = mad(hitGeomError, hitGeomNormal, hitPosition);
        direction = wi;

        return true;
    }
}
