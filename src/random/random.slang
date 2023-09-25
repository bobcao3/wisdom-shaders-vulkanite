import math;

interface IRandomNumberGenerator {
    [mutating]
    float nextRand();
}

int randomInt<T : IRandomNumberGenerator>(inout T rng, int min, int max) {
    return min + (int)(rng.nextRand() * (max - min));
}

float randomFloat<T : IRandomNumberGenerator>(inout T rng, float min, float max) {
    return min + rng.nextRand() * (max - min);
}

float2 uniform2D<T : IRandomNumberGenerator>(inout T rng) {
    return float2(rng.nextRand(), rng.nextRand());
}

float3 uniform3D<T : IRandomNumberGenerator>(inout T rng) {
    return float3(rng.nextRand(), rng.nextRand(), rng.nextRand());
}

float3 orientedCosineHemisphere<T : IRandomNumberGenerator>(inout T rng, float3 n) {
    float2 u = uniform2D(rng) * (1.0f - 1e-5f);
    let a = 1.0 - 2.0 * u.x;
    let b = sqrt(1.0 - a * a);
    let phi = 2.0 * PI * u.y;
    let x = n.x + b * cos(phi);
    let y = n.y + a;
    let z = n.z + b * sin(phi);
    return normalize(float3(x, y, z));
}

float orientedCosineHemispherePdf(float3 n, float3 d) {
    return dot(n, d) / PI;
}

float3 randomCone<T : IRandomNumberGenerator>(inout T rng, float cosThetaMax) {
    float2 u = uniform2D(rng);
    let cosTheta = (1.0 - u.x) + u.x * cosThetaMax;
    let sinTheta = sqrt(1.0 - cosTheta * cosTheta);
    let phi = 2.0 * PI * u.y;
    let x = sinTheta * cos(phi);
    let y = sinTheta * sin(phi);
    let z = cosTheta;
    return float3(x, y, z);
}

float3 orientedCone<T : IRandomNumberGenerator>(inout T rng, float3 n, float cosThetaMax) {
    float3 d = randomCone(rng, cosThetaMax);
    float3 T = getPerpendicularVector(n);
    float3 B = cross(n, T);
    return d.x * T + d.y * B + d.z * n;
}
