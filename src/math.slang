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
