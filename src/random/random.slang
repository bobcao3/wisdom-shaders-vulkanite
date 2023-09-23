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

float3 orientedCosineHemisphere<T : IRandomNumberGenerator>(inout T rng, float3 n, out float pdf) {
    float2 u = uniform2D(rng) * (1.0f - 1e-5f);
    let a = 1.0 - 2.0 * u.x;
    let b = sqrt(1.0 - a * a);
    let phi = 2.0 * PI * u.y;
    let x = n.x + b * cos(phi);
    let y = n.y + a;
    let z = n.z + b * sin(phi);
    pdf = a / PI;
    return normalize(float3(x, y, z));
}

float orientedCosineHemispherePdf(float3 n, float3 d) {
    return dot(n, d) / PI;
}
