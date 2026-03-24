#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

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

    float density = 0.96 + (broadVariation * 0.07) + (softVariation * 0.035);
    density = clamp(density, 0.84, 1.08);

    return half4(color.rgb, color.a * half(density));
}
