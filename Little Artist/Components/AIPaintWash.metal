//
//  AIPaintWash.metal
//  Little Artist
//
//  A soft watercolor-wash pulse shader for AI processing states.
//  Renders organic paint-like blobs that breathe and shift using
//  smooth noise functions, matching the warm children's art theme.
//

#include <metal_stdlib>
using namespace metal;

// Smooth noise helper
float hash(float2 p) {
    float3 p3 = fract(float3(p.xyx) * 0.13);
    p3 += dot(p3, p3.yzx + 3.333);
    return fract((p3.x + p3.y) * p3.z);
}

float noise(float2 p) {
    float2 i = floor(p);
    float2 f = fract(p);
    f = f * f * (3.0 - 2.0 * f);

    float a = hash(i);
    float b = hash(i + float2(1.0, 0.0));
    float c = hash(i + float2(0.0, 1.0));
    float d = hash(i + float2(1.0, 1.0));

    return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

float fbm(float2 p) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 4; i++) {
        value += amplitude * noise(p);
        p *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

// Brand palette as constants
constant float3 coral    = float3(0.949, 0.471, 0.294);  // #F2784B
constant float3 lavender = float3(0.722, 0.663, 0.831);  // #B8A9D4
constant float3 sky      = float3(0.494, 0.722, 0.855);  // #7EB8DA
constant float3 sage     = float3(0.659, 0.773, 0.627);  // #A8C5A0
constant float3 cream    = float3(1.000, 0.973, 0.941);  // #FFF8F0

[[ stitchable ]]
half4 aiPaintWash(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size;

    // Slow organic motion
    float t = time * 0.4;

    // Create several drifting blobs using fbm noise
    float blob1 = fbm(uv * 3.0 + float2(t * 0.3, t * 0.2));
    float blob2 = fbm(uv * 2.5 + float2(-t * 0.25, t * 0.35));
    float blob3 = fbm(uv * 4.0 + float2(t * 0.15, -t * 0.28));

    // Breathing pulse: slow sine wave
    float pulse = 0.5 + 0.5 * sin(t * 1.8);
    float pulse2 = 0.5 + 0.5 * sin(t * 1.3 + 1.0);

    // Mix brand colours based on noise positions
    float3 col = cream;
    col = mix(col, coral,    smoothstep(0.35, 0.65, blob1) * 0.55 * pulse);
    col = mix(col, lavender, smoothstep(0.40, 0.70, blob2) * 0.45 * pulse2);
    col = mix(col, sky,      smoothstep(0.38, 0.68, blob3) * 0.40 * pulse);
    col = mix(col, sage,     smoothstep(0.45, 0.72, blob1 * blob2) * 0.30 * pulse2);

    // Soft radial vignette: stronger at edges
    float2 center = uv - 0.5;
    float vignette = 1.0 - dot(center, center) * 1.2;
    vignette = smoothstep(0.0, 1.0, vignette);

    // Overall opacity: fades to transparent at edges
    float alpha = smoothstep(0.15, 0.55, vignette) * 0.75;

    // Add subtle sparkle highlights
    float sparkle = noise(uv * 20.0 + float2(t * 2.0, 0.0));
    sparkle = smoothstep(0.92, 0.98, sparkle) * pulse * 0.4;
    col += float3(sparkle);

    return half4(half3(col), half(alpha));
}

// Simpler version for the button border shimmer
[[ stitchable ]]
half4 aiPaintBorder(float2 position, half4 color, float2 size, float time) {
    float2 uv = position / size;
    float t = time * 0.6;

    // Flowing gradient along the perimeter
    float angle = atan2(uv.y - 0.5, uv.x - 0.5);
    float normalized = (angle / 3.14159265 + 1.0) * 0.5; // 0..1

    // Shift the colour wheel over time
    float shifted = fract(normalized + t * 0.3);

    // Map to brand palette with smooth blending
    float3 col;
    if (shifted < 0.25) {
        col = mix(coral, lavender, shifted * 4.0);
    } else if (shifted < 0.5) {
        col = mix(lavender, sky, (shifted - 0.25) * 4.0);
    } else if (shifted < 0.75) {
        col = mix(sky, sage, (shifted - 0.5) * 4.0);
    } else {
        col = mix(sage, coral, (shifted - 0.75) * 4.0);
    }

    // Pulse intensity
    float pulse = 0.7 + 0.3 * sin(t * 2.0 + shifted * 6.28);
    float alpha = float(color.a) * pulse;

    return half4(half3(col), half(alpha));
}
