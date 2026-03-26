///////////////////////////////////////////////////////////
// VERTEX SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_VERTEX
void main() {
#if INSTANCING__ON
    vec3 worldPos = mul(mtxFromCols(i_data1, i_data2, i_data3, vec4(0.0, 0.0, 0.0, 1.0)), vec4(a_position, 1.0)).xyz;
#else
    vec3 worldPos = mul(u_model[0], vec4(a_position, 1.0)).xyz;
#endif
    vec4 clipPos = mul(u_viewProj, vec4(worldPos, 1.0));
    v_clipPos = clipPos;
    v_texcoord0 = a_texcoord0;
    v_worldPos = worldPos;
    gl_Position = clipPos;
}
#endif




///////////////////////////////////////////////////////////
// FRAGMENT/PIXEL SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_FRAGMENT
uniform highp vec4 MoonDir;
uniform highp vec4 SunDir;
uniform highp vec4 Time;
uniform highp vec4 WorldOrigin;
uniform highp vec4 SkyProbeUVFadeParameters;

SAMPLER2D_HIGHP_AUTOREG(s_SunMoonTexture);
SAMPLER2D_HIGHP_AUTOREG(s_PreviousFrameAverageLuminance);
SAMPLER2DARRAY_AUTOREG(s_ScatteringBuffer);

#include "./lib/common.glsl"
#include "./lib/atmosphere.glsl"
#include "./lib/froxel_util.glsl"
#include "./lib/clouds.glsl"

void main() {
    vec3 worldDir = normalize(v_worldPos);
    AtmosphereParams atmParams;
    atmParams.rayStart = vec3(0.0, 0.0, 0.0);
    atmParams.rayDir = worldDir;
    atmParams.lightDir = vec3_splat(0.0);
    atmParams.rayLength = 1e10;
    atmParams.aerial = 1.0;
    atmParams.occlusion = 1.0;
    atmParams.mieMod = 1.0;
    vec4 transmittance;
    vec3 unused = GetAtmosphere(atmParams, transmittance);

    //sun without limb darkening
    float costh = dot(worldDir, SunDir.xyz);
    float disc = sqrt(smoothstep(cos(0.00436 * 4.0), 1.0, costh));
    vec3 outColor = disc * transmittance.rgb * transmittance.rgb * 25000.0;

#ifdef VOLUMETRIC_CLOUDS_ENABLED
    float dither = texelFetch(s_CausticsTexture, ivec3(ivec2(gl_FragCoord.xy) % 256, 1), 0).r;
    CloudSetup cloudSetup = calcCloudSetup(worldDir.y, -WorldOrigin.y);
    float cloudTransmittance = calcCloudTransmittanceOnly(worldDir, 0.0, dither, false, cloudSetup);
    outColor *= cloudTransmittance * cloudTransmittance * cloudTransmittance; //this is shiny sun, so need extra transmission to hide it
#endif

    //mask moon position and sample the texture
    if (dot(worldDir, MoonDir.xyz) > 0.0) {
        vec3 tex = texture2D(s_SunMoonTexture, v_texcoord0).rgb;
        float texlum = luminance(tex);
        outColor = texlum * texlum * transmittance.rgb;
#ifdef VOLUMETRIC_CLOUDS_ENABLED
        outColor *= cloudTransmittance;
#endif
    }

    vec3 projPos = v_clipPos.xyz / v_clipPos.w;
    vec3 uvw = ndcToVolume(projPos);
    vec4 volumetricFog = sampleVolume(s_ScatteringBuffer, uvw);
    if (VolumeScatteringEnabledAndPointLightVolumetricsEnabled.x > 0.0) outColor *= volumetricFog.a;

#if FORWARD_PBR_TRANSPARENT_PASS
    outColor = preExposeLighting(outColor, texture2D(s_PreviousFrameAverageLuminance, vec2_splat(0.5)).r);
    gl_FragColor = vec4(outColor, 1.0);
#else
    gl_FragColor = vec4_splat(0.0);
#endif
}
#endif
