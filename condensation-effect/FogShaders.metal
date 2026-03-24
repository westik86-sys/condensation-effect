#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

static float hash21(float2 p) {
    p = fract(p * float2(123.34, 456.21));
    p += dot(p, p + 45.32);
    return fract(p.x * p.y);
}

static float valueNoise(float2 p) {
    float2 cell = floor(p);
    float2 local = fract(p);
    float2 smooth = local * local * (3.0 - 2.0 * local);

    float bottomLeft = hash21(cell);
    float bottomRight = hash21(cell + float2(1.0, 0.0));
    float topLeft = hash21(cell + float2(0.0, 1.0));
    float topRight = hash21(cell + float2(1.0, 1.0));

    float bottom = mix(bottomLeft, bottomRight, smooth.x);
    float top = mix(topLeft, topRight, smooth.x);
    return mix(bottom, top, smooth.y);
}

static float fogNoise(float2 uv) {
    float noise = 0.0;
    noise += valueNoise(uv * 3.2) * 0.55;
    noise += valueNoise(uv * 6.7 + 11.4) * 0.30;
    noise += valueNoise(uv * 12.9 + 27.1) * 0.15;
    return noise;
}

[[ stitchable ]] half4 organicFog(float2 position, half4 color, float2 size) {
    if (size.x <= 0.0 || size.y <= 0.0) {
        return color;
    }

    float2 uv = position / size;

    float broadVariation =
        sin(uv.x * 5.4 + 0.6) * sin(uv.y * 4.8 - 1.1);

    float softVariation =
        sin((uv.x + uv.y) * 7.2 + 0.9) * 0.5 +
        sin(uv.x * 10.5 - uv.y * 6.3 - 0.4) * 0.5;

    float proceduralVariation = (fogNoise(uv + float2(0.17, 0.08)) - 0.5) * 0.12;

    float density =
        0.95 +
        (broadVariation * 0.05) +
        (softVariation * 0.025) +
        proceduralVariation;
    density = clamp(density, 0.82, 1.06);

    return half4(color.rgb, color.a * half(density));
}
