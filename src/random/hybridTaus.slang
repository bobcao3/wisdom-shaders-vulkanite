import random;

struct HybridTausGenerator : IRandomNumberGenerator {
    uint z1, z2, z3, z4;

    __init(uint4 seed) {
        z1 = seed.x;
        z2 = seed.y;
        z3 = seed.z;
        z4 = seed.w;
    }

    static uint LCGStep(inout uint z, uint A, uint C) {
        return z = (A * z + C);
    }

    static uint TausStep(inout uint z, int S1, int S2, int S3, uint M) {
        uint b = (((z << S1) ^ z) >> S2);
        return z = (((z & M) << S3) ^ b);
    }

    [mutating]
    float nextRand() {
        // Combined period is lcm(p1,p2,p3,p4)~ 2^121
        return 2.3283064365387e-10 * (                // Periods
            TausStep(z1, 13, 19, 12, 4294967294UL) ^  // p1=2^31-1
            TausStep(z2, 2, 25, 4, 4294967288UL) ^    // p2=2^30-1
            TausStep(z3, 3, 11, 17, 4294967280UL) ^   // p3=2^28-1
            LCGStep(z4, 1664525, 1013904223UL)        // p4=2^32
        );
    }
}
