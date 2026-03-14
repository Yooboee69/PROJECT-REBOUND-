///////////////////////////////////////////////////////////
// VERTEX SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_VERTEX
void main() {
    v_texcoord0 = a_texcoord0;
    gl_Position = vec4(a_position.xy * 2.0 - 1.0, 0.0, 1.0);
}
#endif




///////////////////////////////////////////////////////////
// FRAGMENT/PIXEL SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_FRAGMENT
uniform highp vec4 TonemapParams0;
uniform highp vec4 ExposureCompensation;
uniform highp vec4 LuminanceMinMaxAndWhitePointAndMinWhitePoint;

SAMPLER2D_HIGHP_AUTOREG(s_ColorTexture);
SAMPLER2D_HIGHP_AUTOREG(s_PreExposureLuminance);
SAMPLER2D_HIGHP_AUTOREG(s_AverageLuminance);
SAMPLER2D_HIGHP_AUTOREG(s_CustomExposureCompensation);
SAMPLER2D_HIGHP_AUTOREG(s_RasterizedColor);

#include "./lib/common.glsl"

// https://github.com/dmnsgn/glsl-tone-map/blob/main/agx.glsl
vec3 agx(vec3 color) {
    mat3 LINEAR_SRGB_TO_LINEAR_REC2020 = mtxFromCols(
        vec3(0.6274, 0.0691, 0.0164),
        vec3(0.3293, 0.9195, 0.0880),
        vec3(0.0433, 0.0113, 0.8956)
    );
    color = mul(LINEAR_SRGB_TO_LINEAR_REC2020, color);


    // Input transform (inset)
    // Converted to column major from blender: https://github.com/blender/blender/blob/fc08f7491e7eba994d86b610e5ec757f9c62ac81/release/datafiles/colormanagement/config.ocio#L358
    mat3 AgXInsetMatrix = mtxFromCols(
        vec3(0.856627153315983, 0.137318972929847, 0.11189821299995),
        vec3(0.0951212405381588, 0.761241990602591, 0.0767994186031903),
        vec3(0.0482516061458583, 0.101439036467562, 0.811302368396859)
    );
    color = mul(AgXInsetMatrix, color);

    color = max(color, 1e-10); // From Filament: avoid 0 or negative numbers for log2

    // Log2 space encoding
    CONST(float) AgxMinEv = -12.47393;
    CONST(float) AgxMaxEv = 4.026069;
    color = clamp(log2(color), AgxMinEv, AgxMaxEv);
    color = (color - AgxMinEv) / (AgxMaxEv - AgxMinEv);

    color = saturate(color); // From Filament

    // Apply sigmoid function approximation
    // Mean error^2: 3.6705141e-06
    vec3 x2 = color * color;
    vec3 x4 = x2 * x2;
    color = + 15.5   * x4 * x2
            - 40.14  * x4 * color
            + 31.96  * x4
            - 6.868  * x2 * color
            + 0.4298 * x2
            + 0.1191 * color
            - 0.00232;

    // Inverse input transform (outset)
    // Converted to column major and inverted from https://github.com/EaryChow/AgX_LUT_Gen/blob/ab7415eca3cbeb14fd55deb1de6d7b2d699a1bb9/AgXBaseRec2020.py#L25
    // https://github.com/google/filament/blob/bac8e58ee7009db4d348875d274daf4dd78a3bd1/filament/src/ToneMapper.cpp#L273-L278
    mat3 AgXOutsetMatrix = mtxFromCols(
        vec3(1.1271005818144368, -0.1413297634984383, -0.14132976349843826),
        vec3(-0.11060664309660323, 1.157823702216272, -0.11060664309660294),
        vec3(-0.016493938717834573, -0.016493938717834257, 1.2519364065950405)
    );
    color = mul(AgXOutsetMatrix, color);


    mat3 LINEAR_REC2020_TO_LINEAR_SRGB = mtxFromCols(
        vec3(1.6605, -0.1246, -0.0182),
        vec3(-0.5876, 1.1329, -0.1006),
        vec3(-0.0728, -0.0083, 1.1187)
    );
    color = mul(LINEAR_REC2020_TO_LINEAR_SRGB, color);

    color = saturate(color);
    return color;
}

void main() {
    vec3 inputColor = texture2D(s_ColorTexture, v_texcoord0).rgb;
    inputColor = max(inputColor, vec3_splat(0.0));


    // deobfuscated from vanilla material, for now just leave it like this
    if (TonemapParams0.b > 0.0) {
        float preExposureLum = texture2D(s_PreExposureLuminance, vec2_splat(0.5)).r;
        inputColor = inputColor / vec3_splat((MIDDLE_GRAY / preExposureLum) + EPSILON);
    }
    float refLuminance = MIDDLE_GRAY;
    if (ExposureCompensation.b > 0.5) {
        float avgLum = texture2D(s_AverageLuminance, vec2_splat(0.5)).r;
        refLuminance = clamp(avgLum, LuminanceMinMaxAndWhitePointAndMinWhitePoint.r, LuminanceMinMaxAndWhitePointAndMinWhitePoint.g);
    }
    int exposureMode = int(ExposureCompensation.r);
    float exposureValue = ExposureCompensation.g; //manual
    if (exposureMode > 0 && exposureMode < 2) {
        //automatic
        exposureValue = 1.03 - (2.0 / ((0.43429 * log(refLuminance + 1.0)) + 2.0));
    } else if (exposureMode > 1) {
        //custom
        float lumMin = LuminanceMinMaxAndWhitePointAndMinWhitePoint.r;
        float lumMax = LuminanceMinMaxAndWhitePointAndMinWhitePoint.g;
        float t = (lumMin == lumMax) ? 0.5 : ((log2(refLuminance) + 3.0) - (log2(lumMin) + 3.0)) / ((log2(lumMax) + 3.0) - (log2(lumMin) + 3.0));
        exposureValue = texture2D(s_CustomExposureCompensation, vec2(t, 0.5)).r;
    }


    float exposure = (MIDDLE_GRAY / refLuminance) * exposureValue;
    vec3 outColor = agx(inputColor * exposure);

    vec4 rasterColor = texture2D(s_RasterizedColor, v_texcoord0);
    rasterColor.rgb = agx(rasterColor.rgb);
    outColor = mix(outColor, rasterColor.rgb, rasterColor.a);

    gl_FragColor = vec4(outColor, 1.0);
}
#endif //BGFX_SHADER_TYPE_FRAGMENT
