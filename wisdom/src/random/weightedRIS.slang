import random;

struct WeightedReservior {
    float ws;
    float wR;

    __init() {
        ws = 0;
        wR = 1.0;
    }

    [[mutating]]
    bool add<T : IRandomNumberGenerator>(inout T rng, float wi) {
        ws += ws + wi;
        let eta = rng.nextRand();
        if (eta <= wi / ws) {
            wR = wi;
            return true;
        }
        return false;
    }

    float getProb() {
        return wR / ws;
    }
};
