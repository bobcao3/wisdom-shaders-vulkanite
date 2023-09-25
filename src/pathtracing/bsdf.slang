import random.random;
import math;

interface IBsdf {
    // Returns the sampled wi, and the pdf of the sample
    void sample<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 nGeom, float3 wo, out float pdf, out float3 wi);

    // Returns the pdf of the sampled direction
    float pdf(float3 n, float3 nGeom, float3 wi, float3 wo);

    // Evaluates the BSDF for the given incoming and outgoing directions
    float3 evaluate(float3 n, float3 nGeom, float3 wi, float3 wo);
}

struct LambertianBSDF : IBsdf {
    float3 albedo;

    __init(float3 albedo) {
        this.albedo = albedo;
    }

    void sample<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 nGeom, float3 wo, out float pdf, out float3 wi) {
        wi = orientedCosineHemisphere(rng, n);
        pdf = orientedCosineHemispherePdf(n, wi);
    }

    float pdf(float3 n, float3 nGeom, float3 wi, float3 wo) {
        return orientedCosineHemispherePdf(n, wi);
    }

    float3 evaluate(float3 n, float3 nGeom, float3 wi, float3 wo) {
        return albedo / PI * saturate(dot(wi, n));
    }
}

struct DisneyDiffuseBSDf : IBsdf {
    float3 albedo;
    float a2;

    __init(float3 albedo, float roughness) {
        this.albedo = albedo;
        this.a2 = roughness; // Note: this is roughness^2
    }

    void sample<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 nGeom, float3 wo, out float pdf, out float3 wi) {
        wi = orientedCosineHemisphere(rng, n);
        pdf = orientedCosineHemispherePdf(n, wi);
    }

    float pdf(float3 n, float3 nGeom, float3 wi, float3 wo) {
        return orientedCosineHemispherePdf(n, wi);
    }

    float3 evaluate(float3 n, float3 nGeom, float3 wi, float3 wo) {
        let h = normalize(wi + wo);
        let cosThetaD = saturate(dot(h, n));
        let cosThetaL = saturate(dot(wi, n));
        let cosThetaV = saturate(dot(wo, n));
        let fD90 = 0.5 + 2.0 * a2 * pow(cosThetaD, 2.0);
        let fd = (albedo / PI) *
                 (1.0 + (fD90 - 1.0) * pow(1.0 - cosThetaL, 5.0)) *
                 (1.0 + (fD90 - 1.0) * pow(1.0 - cosThetaV, 5.0));
        return fd * cosThetaL;
    }
};

struct GGXSchlickBSDF : IBsdf {
    float3 f0;
    float3 kS;
    float a2;

    __init(float3 kS, float3 f0, float roughness) {
        this.kS = kS;
        this.a2 = roughness; // Note: this is roughness^2
    }

    float ggxNormalDistribution(float NdotH) {
        float d = ((NdotH * a2 - NdotH) * NdotH + 1);
        return a2 / (d * d * PI);
    }

    float schlickMaskingTerm(float NdotL, float NdotV) {
        // Karis notes they use alpha / 2 (or roughness^2 / 2)
        float k = a2 / 2;

        // Compute G(v) and G(l).  These equations directly from Schlick 1994
        //     (Though note, Schlick's notation is cryptic and confusing.)
        float g_v = NdotV / (NdotV * (1 - k) + k);
        float g_l = NdotL / (NdotL * (1 - k) + k);
        return g_v * g_l;
    }

    static float3 schlickFresnel(float3 f0, float lDotH) {
        return f0 + (float3(1.0f, 1.0f, 1.0f) - f0) * pow(1.0f - lDotH, 5.0f);
    }

    // When using this function to sample, the probability density is:
    //      pdf = D * NdotH / (4 * HdotV)
    float3 getGGXMicrofacet<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 nGeom, float3 wo) {
        // Get our uniform random numbers
        float2 randVal = uniform2D(rng);

        // Get an orthonormal basis from the normal
        float3 B = getPerpendicularVector(n);
        float3 T = cross(B, n);

        // GGX NDF sampling
        float cosThetaH = sqrt(max(0.0f, (1.0 - randVal.x) / ((a2 - 1.0) * randVal.x + 1)));
        float sinThetaH = sqrt(max(0.0f, 1.0f - cosThetaH * cosThetaH));
        float phiH = randVal.y * PI * 2.0f;

        // Get our GGX NDF sample (i.e., the half vector)
        return T * (sinThetaH * cos(phiH)) +
               B * (sinThetaH * sin(phiH)) +
               n * cosThetaH;
    }

    void sample<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 nGeom, float3 wo, out float pdf, out float3 wi) {
        float3 h = getGGXMicrofacet(rng, n, nGeom, wo);
        wi = reflect(-wo, h);
        float NdotH = saturate(dot(n, h));
        float HdotV = saturate(dot(h, wo));
        pdf = ggxNormalDistribution(NdotH) * NdotH / (4 * HdotV);
    }

    float pdf(float3 n, float3 nGeom, float3 wi, float3 wo) {
        float3 h = normalize(wi + wo);
        float NdotH = saturate(dot(n, h));
        float HdotV = saturate(dot(h, wo));
        return ggxNormalDistribution(NdotH) * NdotH / (4 * HdotV);
    }

    float3 evaluate(float3 n, float3 nGeom, float3 wi, float3 wo) {
        float3 h = normalize(wi + wo);
        float NdotH = saturate(dot(n, h));
        float NdotL = saturate(dot(n, wi));
        float NdotV = saturate(dot(n, wo));
        float D = ggxNormalDistribution(NdotH);
        float G = schlickMaskingTerm(NdotL, NdotV);
        float3 F = schlickFresnel(f0, saturate(dot(wo, h)));
        return kS * D * G / (4 * NdotV); // NdotL got cancelled out
    }
}

// Mix between two BSDFs
struct MixBSDF<BsdfA : IBsdf, BsdfB : IBsdf> : IBsdf {
    float mixFactor;

    BsdfA fA;
    BsdfB fB;

    __init(float mixFactor, BsdfA fA, BsdfB fB) {
        this.mixFactor = mixFactor;
        this.fA = fA;
        this.fB = fB;
    }

    float getBsdfAProbability() {
        return mixFactor;
    }

    void sample<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 nGeom, float3 wo, out float pdf, out float3 wi) {
        float p = getBsdfAProbability();
        if (rng.nextRand() < p) {
            fA.sample(rng, n, nGeom, wo, pdf, wi);
            pdf *= p;
        } else {
            fB.sample(rng, n, nGeom, wo, pdf, wi);
            pdf *= 1.0f - p;
        }
    }

    float pdf(float3 n, float3 nGeom, float3 wi, float3 wo) {
        float p = getBsdfAProbability();
        return fA.pdf(n, nGeom, wi, wo) * p + fB.pdf(n, nGeom, wi, wo) * (1.0f - p);
    }

    float3 evaluate(float3 n, float3 nGeom, float3 wi, float3 wo) {
        var result = float3(0.0);
        if (mixFactor > 0.0f) {
            result += fA.evaluate(n, nGeom, wi, wo) * mixFactor;
        }
        if (mixFactor < 1.0f) {
            result += fB.evaluate(n, nGeom, wi, wo) * (1.0f - mixFactor);
        }
        return result;
    }
}

struct NormalFlipBSDF<BaseF : IBsdf> : IBsdf {
    BaseF base;

    __init(BaseF base) {
        this.base = base;
    }

    void sample<T : IRandomNumberGenerator>(inout T rng, float3 n, float3 nGeom, float3 wo, out float pdf, out float3 wi) {
        base.sample(rng, n, nGeom, wo, pdf, wi);
        if (dot(wi, nGeom) < 0.0) {
            wi = reflect(n, nGeom);
        }
    }

    float pdf(float3 n, float3 nGeom, float3 wi, float3 wo) {
        return base.pdf(n, nGeom, wi, wo);
    }

    float3 evaluate(float3 n, float3 nGeom, float3 wi, float3 wo) {
        if (dot(wi, n) < 0.0) {
            n = -reflect(n, nGeom);
        }
        return base.evaluate(n, nGeom, wi, wo);
    }
}

/*
// https://blog.unity.com/technology/microfacet-based-normal-mapping-for-robust-monte-carlo-path-tracing
struct MicrofacetAnalyticBSDF<BaseF : IBsdf> : IBsdf {
    BaseF base;

    __init(BaseF base) {
        this.base = base;
    }

    // Notations:
    // wi: incoming direction
    // wo: outgoing direction
    // wp: shading normal
    // wg: geometric normal
    // wt: tangent facet
    // wm: microfacet normal (from NDF)

    // Projected area a_p, Eq. 6
    static float Ap(float3 wp, float3 wg, float3 wi) {
        return dot(wi, wp) / dot(wi, wg);
    }

    // Projected area a_t, Eq. 7
    static float At(float3 wp, float3 wg, float3 wt, float3 wi) {
        return dot(wi, wt) * sqrt(1.0 - pow(dot(wp, wg), 2.0)) / dot(wp, wg);
    }

    // Masking function, Eq. 13
    static float G1(float3 wp, float3 wg, float3 wt, float3 wi, float3 wm) {
        return step(0.0, dot(wi, wm)) * min(1.0, dot(wi, wg) / (Ap(wp, wg, wi) + At(wp, wg, wt, wi)));
    }

    
}
*/
