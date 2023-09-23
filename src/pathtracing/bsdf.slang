import random.random;
import math;

interface IBsdf {
    // Returns the evaluated brdf, sampled wi, and the pdf of the sample
    float3 sample<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 wo, out float pdf, out float3 wi);

    // Returns the pdf of the sampled direction
    float pdf(float3 n, float3 wi, float3 wo);

    // Evaluates the BSDF for the given incoming and outgoing directions
    float3 evaluate(float3 n, float3 wi, float3 wo);
}

struct LambertianBSDF : IBsdf {
    float3 albedo;

    __init(float3 albedo) {
        this.albedo = albedo;
    }

    float3 sample<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 wo, out float pdf, out float3 wi) {
        wi = orientedCosineHemisphere(rng, n, pdf);
        return albedo;
    }

    float pdf(float3 n, float3 wi, float3 wo) {
        return orientedCosineHemispherePdf(n, wi);
    }

    float3 evaluate(float3 n, float3 wi, float3 wo) {
        return albedo / PI;
    }
}
