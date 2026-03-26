// deobfuscated from vanilla material and modified to remove black squares bug

///////////////////////////////////////////////////////////
// VERTEX SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_VERTEX
uniform vec4 ViewportScale;
void main() {
    v_texcoord0 = a_texcoord0 * ViewportScale.xy;
    gl_Position = vec4(a_position.xy * 2.0 - 1.0, 0.0, 1.0);
}
#endif



///////////////////////////////////////////////////////////
// FRAGMENT/PIXEL SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_FRAGMENT
uniform highp vec4 ViewportScale;
uniform highp vec4 BloomParams;

#if BLOOM_BLEND_PASS
SAMPLER2D_HIGHP_AUTOREG(s_HDRi);
#endif

#if THRESHOLDED_DOWN_SAMPLE_PASS
SAMPLER2D_HIGHP_AUTOREG(s_AverageLuminance);
#endif

SAMPLER2D_HIGHP_AUTOREG(s_BlurPyramidTexture);

#include "./lib/common.glsl"

void main() {
    vec2 uv = (floor(ViewportScale.zw * ViewportScale.xy) - 0.5) / ViewportScale.zw;

#if BLOOM_BLEND_PASS
    vec2 ofs = (ViewportScale.xy * 4.0) * (vec2_splat(0.5) / ViewportScale.zw);

    vec4 sample1 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(0.5 * ofs.x, 0.5 * ofs.y), uv));
    vec4 sample2 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-0.5 * ofs.x, 0.5 * ofs.y), uv));
    vec4 sample3 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(0.5 * ofs.x, -0.5 * ofs.y), uv));
    vec4 sample4 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-0.5 * ofs.x, -0.5 * ofs.y), uv));
    vec4 sample5 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(ofs.x, ofs.y), uv));
    vec4 sample6 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-ofs.x, ofs.y), uv));
    vec4 sample7 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(ofs.x, -ofs.y), uv));
    vec4 sample8 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-ofs.x, -ofs.y), uv));

    vec4 bloom = (sample1 * 0.16) + (sample2 * 0.16) + (sample3 * 0.16) + (sample4 * 0.16) + (sample5 * 0.083) + (sample6 * 0.083) + (sample7 * 0.083) + (sample8 * 0.083);

    vec3 outColor = texture2D(s_HDRi, v_texcoord0).rgb + bloom.rgb * BloomParams.r;

    gl_FragColor = vec4(outColor, 1.0);
#endif

#if DF_DOWN_SAMPLE_PASS
    vec2 ofs = (ViewportScale.xy * 1.5) * (vec2_splat(2.0) / ViewportScale.zw);

    vec4 sample0 = texture2D(s_BlurPyramidTexture, min(v_texcoord0, uv));
    vec4 sample1 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(ofs.x, ofs.y), uv));
    vec4 sample2 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-ofs.x, ofs.y), uv));
    vec4 sample3 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(ofs.x, -ofs.y), uv));
    vec4 sample4 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-ofs.x, -ofs.y), uv));

    vec4 outColor = (sample0 * 0.5) + (sample1 * 0.125) + (sample2 * 0.125) + (sample3 * 0.125) + (sample4 * 0.125);
    outColor.rgb = max(outColor.rgb, vec3_splat(EPSILON));

    gl_FragColor = outColor;
#endif

#if DF_UP_SAMPLE_PASS
    vec2 ofs = (ViewportScale.xy * 4.0) * (vec2_splat(0.5) / ViewportScale.zw);

    vec4 sample1 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(0.5 * ofs.x, 0.5 * ofs.y), uv));
    vec4 sample2 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-0.5 * ofs.x, 0.5 * ofs.y), uv));
    vec4 sample3 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(0.5 * ofs.x, -0.5 * ofs.y), uv));
    vec4 sample4 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-0.5 * ofs.x, -0.5 * ofs.y), uv));
    vec4 sample5 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(ofs.x, ofs.y), uv));
    vec4 sample6 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-ofs.x, ofs.y), uv));
    vec4 sample7 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(ofs.x, -ofs.y), uv));
    vec4 sample8 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-ofs.x, -ofs.y), uv));

    vec4 outColor = (sample1 * 0.16) + (sample2 * 0.16) + (sample3 * 0.16) + (sample4 * 0.16) + (sample5 * 0.083) + (sample6 * 0.083) + (sample7 * 0.083) + (sample8 * 0.083);
    outColor.rgb = max(outColor.rgb, vec3_splat(EPSILON));

    gl_FragColor = outColor;
#endif

#if THRESHOLDED_DOWN_SAMPLE_PASS
    vec2 ofs = (ViewportScale.xy * 1.5) * (vec2_splat(2.0) / ViewportScale.zw);

    float brightnessThreshold = BloomParams.y * texture2D(s_AverageLuminance, vec2_splat(0.5)).r;

    vec4 sample0 = texture2D(s_BlurPyramidTexture, min(v_texcoord0, uv));
    float luminance0 = luminance(sample0.rgb);
    vec4 maskedCenter = sample0 * step(brightnessThreshold, luminance0);

    vec4 sample1 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(ofs.x, ofs.y), uv));
    float luminance1 = luminance(sample1.rgb);
    vec4 maskedSample1 = sample1 * step(brightnessThreshold, luminance1);

    vec4 sample2 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-ofs.x, ofs.y), uv));
    float luminance2 = luminance(sample2.rgb);
    vec4 maskedSample2 = sample2 * step(brightnessThreshold, luminance2);

    vec4 sample3 = texture2D(s_BlurPyramidTexture,  min(v_texcoord0 + vec2(ofs.x, -ofs.y), uv));
    float luminance3 = luminance(sample3.rgb);
    vec4 maskedSample3 = sample3 * step(brightnessThreshold, luminance3);

    vec4 sample4 = texture2D(s_BlurPyramidTexture, min(v_texcoord0 + vec2(-ofs.x, -ofs.y), uv));
    float luminance4 = luminance(sample4.rgb);
    vec4 maskedSample4 = sample4 * step(brightnessThreshold, luminance4);

    vec4 outColor = (maskedCenter * 0.5) + (maskedSample1 * 0.125) + (maskedSample2 * 0.125) + (maskedSample3 * 0.125) + (maskedSample4 * 0.125);
    outColor.rgb = max(outColor.rgb, vec3_splat(EPSILON));

    gl_FragColor = outColor;
#endif
}

#endif // BGFX_SHADER_TYPE_FRAGMENT
