import math;
import random;

inline float radicalInverseSpecialized<let base : int>(uint32_t a) {
    let invBase = 1.0 / base;
    uint32_t reversedDigits = 0;
    float invBaseN = 1;
    while (a != 0) {
        uint32_t next = a / base;
        uint32_t digit = a - next * base;
        reversedDigits = reversedDigits * base + digit;
        invBaseN *= invBase;
        a = next;
    }
    return min(reversedDigits * invBaseN, 1.0 - 1e-9);
}

inline float radicalInverse<let base : int>(uint32_t a) {
    if (base == 2) {
        return min((reverseBits32(a) & 0xFFFFFF) * 0x1p-24, 1.0 - 1e-9);
    } else {
        return radicalInverseSpecialized<base>(a);
    }
}

struct HaltonRNG : IRandomNumberGenerator {
    uint32_t index1D;
    uint32_t index2D;
    uint32_t index3D;

    __init(uint3 seed) {
        index1D = seed.x;
        index2D = seed.y;
        index3D = seed.z;
    }

    [mutating]
    float nextRand() {
        return radicalInverse<2>(index1D++);
    }

    [mutating]
    float2 nextRand2D() {
        uint32_t n = index2D++;
        return float2(radicalInverse<2>(n), radicalInverse<3>(n));
    }

    [mutating]
    float3 nextRand3D() {
        uint32_t n = index2D++;
        return float3(radicalInverse<2>(n), radicalInverse<3>(n), radicalInverse<5>(n));
    }
};
