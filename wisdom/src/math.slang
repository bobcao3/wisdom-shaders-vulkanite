static const float PI = 3.14159265358979323846f;
static const half f16PI = half(3.14159265358979323846);
static const float PI2 = 6.28318530717958647692f;
static const half f16PI2 = half(6.28318530717958647692);
static const float invPI = 1.0 / PI;
static const half f16invPI = half(1.0 / PI);

float3 getPerpendicularVector(float3 u) {
    float3 a = abs(u);
    uint xm = ((a.x - a.y) < 0 && (a.x - a.z) < 0) ? 1 : 0;
    uint ym = (a.y - a.z) < 0 ? (1 ^ xm) : 0;
    uint zm = 1 ^ (xm | ym);
    return cross(u, float3(xm, ym, zm));
}

float luminance(float3 c) {
    return dot(c, float3(0.2126, 0.7152, 0.0722));
}

float toRad(float deg) {
    return deg * PI / 180.0;
}

uint32_t reverseBits32(uint32_t n) {
    n = (n << 16) | (n >> 16);
    n = ((n & 0x00ff00ff) << 8) | ((n & 0xff00ff00) >> 8);
    n = ((n & 0x0f0f0f0f) << 4) | ((n & 0xf0f0f0f0) >> 4);
    n = ((n & 0x33333333) << 2) | ((n & 0xcccccccc) >> 2);
    n = ((n & 0x55555555) << 1) | ((n & 0xaaaaaaaa) >> 1);
    return n;
}

float nanToZero(float x) {
    return isnan(x) ? 0.0 : x;
}

float2 nanToZero(float2 x) {
    return select(isnan(x), 0.0, x);
}

float3 nanToZero(float3 x) {
    return select(isnan(x), 0.0, x);
}

float4 nanToZero(float4 x) {
    return select(isnan(x), 0.0, x);
}
