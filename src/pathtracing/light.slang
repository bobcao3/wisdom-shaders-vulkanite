import random.random;

struct DirectionalLight
{
    float3 direction;
    float3 radiance;
    float cosMaxTheta;

    __init(float3 direction, float3 radiance, float angularSize) {
        this.direction = direction;
        this.radiance = radiance;
        this.cosMaxTheta = cos(angularSize * 0.5);
    }

    float3 sample<T : IRandomNumberGenerator>(inout T rng, float3 position, out float3 wi) {
        wi = orientedCone(rng, this.direction, this.cosMaxTheta);
        return radiance;
    }
}
