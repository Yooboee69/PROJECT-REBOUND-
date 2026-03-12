#ifndef COMMON_INCLUDE
#define COMMON_INCLUDE

#define EPSILON 0.0001
#define PI 3.14159265358979
#define HALF_PI 1.57079632679489

#define LUMA_REC709 vec3(0.2126, 0.7152, 0.0722)
#define MIDDLE_GRAY 0.18

#define BLOCK_LIGHT_COLOR vec3(1.0, 0.5, 0.1)
#define BLOCK_LIGHT_INTENSITY 5.0
#define SKY_AMBIENT_INTENSITY 2.0
#define EMISSIVE_MATERIAL_INTENSITY 50.0
#define MIN_AMBIENT_LIGHT 0.001

#define SUN_MAX_ILLUMINANCE 100.0
#define MOON_MAX_ILLUMINANCE 0.1

#define WATER_EXTINCTION_COEFFICIENTS vec3(0.5, 0.35, 0.3)

float luminance(vec3 color) {
    return dot(color, LUMA_REC709);
}

float colorAvg(vec3 color) {
    return (color.r + color.g + color.b) / 3.0;
}

float linearstep(float edge0, float edge1, float x) {
    return clamp((x - edge0) / (edge1 - edge0), 0.0, 1.0);
}

vec3 saturation(vec3 color, float val) {
    return mix(vec3_splat(luminance(color)), color, val);
}

vec3 preExposeLighting(vec3 color, float luminance) {
    return color * (MIDDLE_GRAY / luminance + EPSILON);
}

vec3 unExposeLighting(vec3 color, float luminance) {
    return color / (MIDDLE_GRAY / luminance + EPSILON);
}

uint pack2x8(vec2 values) {
    uvec2 bytes = uvec2(saturate(values) * 255.0) & 0xFFu;
    return (bytes.x << 8) | bytes.y;
}

float sampleDepth(highp sampler2D depthtex, vec2 uv) {
#if BGFX_SHADER_LANGUAGE_GLSL
    return texture2DLod(depthtex, uv, 0.0).r * 2.0 - 1.0;
#else
    return texture2DLod(depthtex, uv, 0.0).r;
#endif
}

//https://github.com/bWFuanVzYWth/OriginShader/blob/main/OriginShader/shaders/glsl/shaderfunction.lin
float ux2l(float l) { return 1.0 / (l * l); }
float uv1x2lig(float uv1x) {
    float l = clamp(1.0 - uv1x, 0.0, 1.0) * 16.0 + 0.5;
    return max(0.0, ux2l(l) - ux2l(15.0) * (1.0 - uv1x));
}

float PhaseM(float costh, float g) {
    float num = (1.0 - g * g) * (1.0 + costh * costh);
    float denom = (2.0 + g * g) * pow((1.0 + g * g - 2.0 * g * costh), 1.5);
    return 3.0 / (8.0 * PI) * num / denom;
}

float PhaseR(float costh) {
    return 3.0 / (16.0 * PI) * (1.0 + costh * costh);
}

#endif
