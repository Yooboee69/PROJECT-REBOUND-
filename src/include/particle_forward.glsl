#include "./lib/common.glsl"
#include "./lib/atmosphere.glsl"


///////////////////////////////////////////////////////////
// VERTEX SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_VERTEX
uniform vec4 SunDir;
uniform vec4 MoonDir;
uniform vec4 DimensionID;

void main(){
#if INSTANCING__ON
    vec3 worldPos = mul(mtxFromCols(i_data1, i_data2, i_data3, vec4(0.0, 0.0, 0.0, 1.0)), vec4(a_position, 1.0)).xyz;
#else
    vec3 worldPos = mul(u_model[0], vec4(a_position, 1.0)).xyz;
#endif
    vec4 clipPos = mul(u_viewProj, vec4(worldPos, 1.0));

    v_clipPos = clipPos;
    v_color0 = a_color0;
    v_worldPos = worldPos;
    v_texcoord0 = a_texcoord0;
    v_ambientLight = a_texcoord1;

    //add smooth transition between night and sunrise, sunset and night
    float sunFade = smoothstep(0.0, 0.1, SunDir.y);
    float moonFade = smoothstep(0.0, 0.1, MoonDir.y);

    v_absorbColor = GetLightTransmittance(SunDir.xyz) * sunFade * PI * M_EXPOSURE_MUL * SUN_MAX_ILLUMINANCE;
    v_absorbColor += GetLightTransmittance(MoonDir.xyz) * moonFade * PI * M_EXPOSURE_MUL * MOON_MAX_ILLUMINANCE;
    v_scatterColor = GetAtmosphere(vec3(0.0, 1.0, 0.0), 1e10, SunDir.xyz, vec3_splat(1.0)) * SUN_MAX_ILLUMINANCE;
    v_scatterColor += GetAtmosphere(vec3(0.0, 1.0, 0.0), 1e10, MoonDir.xyz, vec3_splat(1.0)) * MOON_MAX_ILLUMINANCE;

    if (int(DimensionID.r) != 0) {
        v_absorbColor = vec3_splat(0.0);
        v_scatterColor = vec3_splat(1.0);
    }

    gl_Position = clipPos;
}
#endif //BGFX_SHADER_TYPE_VERTEX




///////////////////////////////////////////////////////////
// FRAGMENT/PIXEL SHADER
///////////////////////////////////////////////////////////
#if BGFX_SHADER_TYPE_FRAGMENT
SAMPLER2D_HIGHP_AUTOREG(s_ParticleTexture);

#if FORWARD_PBR_TRANSPARENT_PASS
uniform highp vec4 CameraIsUnderwater;
uniform highp vec4 CameraLightIntensity;
uniform highp vec4 CausticsParameters;
uniform highp vec4 DirectionalLightSourceWorldSpaceDirection;
uniform highp vec4 MERSUniforms;
uniform highp vec4 PBRTextureFlags;
uniform highp vec4 SunDir;
uniform highp vec4 MoonDir;
uniform highp vec4 DimensionID;
uniform highp vec4 Time;
uniform highp vec4 WorldOrigin;
uniform highp vec4 FogAndDistanceControl;

SAMPLER2D_HIGHP_AUTOREG(s_MERSTexture);
SAMPLER2D_HIGHP_AUTOREG(s_NormalTexture);
SAMPLER2D_HIGHP_AUTOREG(s_PreviousFrameAverageLuminance);

#include "./lib/materials.glsl"
#include "./lib/shadow.glsl"
#include "./lib/bsdf.glsl"
#include "./lib/ibl.glsl"
#include "./lib/volumetrics.glsl"
#endif

void main() {
    vec4 albedo = texture2D(s_ParticleTexture, v_texcoord0);
#if ALPHA_TEST_PASS
    if (albedo.a < 0.5) discard;
    albedo.a = 1.0;
#endif
    albedo *= v_color0;

#if FORWARD_PBR_TRANSPARENT_PASS
    //materials setup
    albedo.rgb = pow(albedo.rgb, vec3_splat(2.2));

    int pbrTextureFlags = int(PBRTextureFlags.r);

    vec4 mers = MERSUniforms;
    if ((pbrTextureFlags & kPBRTextureDataFlagHasMaterialTexture) == kPBRTextureDataFlagHasMaterialTexture) {
        vec4 mersTex = texture2D(s_MERSTexture, v_texcoord0);
        mers.rgb = mersTex.rgb;
        if ((pbrTextureFlags & kPBRTextureDataFlagHasSubsurfaceChannel) == kPBRTextureDataFlagHasSubsurfaceChannel) mers.a = mersTex.a;
    }

    vec3 normal = ((pbrTextureFlags & kPBRTextureDataFlagHasNormalTexture) == kPBRTextureDataFlagHasNormalTexture) ? mul(u_model[0], vec4(texture2D(s_NormalTexture, v_texcoord0).rgb * 2.0 - 1.0, 0.0)).xyz : vec3_splat(0.0);
    vec3 f0 = mix(vec3_splat(0.02), albedo.rgb, mers.r);

    //ambient lighting
    vec3 blockAmbient = BLOCK_LIGHT_COLOR * uv1x2lig(v_ambientLight.r) * BLOCK_LIGHT_INTENSITY;
    vec3 skyAmbient = mix(pow(v_ambientLight.g, 3.0), pow(v_ambientLight.g, 5.0), CameraLightIntensity.g) * (v_scatterColor + v_absorbColor * 0.01) * SKY_AMBIENT_INTENSITY;
    vec3 outColor = albedo.rgb * (1.0 - mers.r) * max(blockAmbient + skyAmbient, vec3_splat(MIN_AMBIENT_LIGHT));

    //directional lighting
    vec3 shadowMap = calcShadowMap(v_worldPos, normal).rgr;

#ifdef VOLUMETRIC_CLOUDS_ENABLED
    vec3 position = v_worldPos - WorldOrigin.xyz;
    CloudSetup cloudSetup = calcCloudSetup(DirectionalLightSourceWorldSpaceDirection.y, position.y);
    float cloudShadow = calcCloudShadow(position, DirectionalLightSourceWorldSpaceDirection.xyz, 2.0, cloudSetup);
    shadowMap.rg = min(shadowMap.rg, vec2_splat(cloudShadow * CLOUD_SHADOW_CONTRIBUTION + (1.0 - CLOUD_SHADOW_CONTRIBUTION)));
    shadowMap.b = min(shadowMap.b, cloudShadow); //used for specular
#endif

    vec3 worldDir = normalize(v_worldPos);
    vec3 bsdf = BSDF(normal, DirectionalLightSourceWorldSpaceDirection.xyz, -worldDir, f0, albedo.rgb, shadowMap, mers.r, mers.b, mers.a);
    outColor += bsdf * v_absorbColor;

    //always lit
    outColor += albedo.rgb * mers.g * EMISSIVE_MATERIAL_INTENSITY;

#ifdef VOLUMETRIC_CLOUDS_ENABLED
    float wDistNorm = length(v_worldPos) / FogAndDistanceControl.z;
    float dither = texelFetch(s_CausticsTexture, ivec3(ivec2(gl_FragCoord.xy) % 256, 1), 0).r;
    applyCumulusClouds(outColor, v_scatterColor, v_absorbColor, worldDir, wDistNorm, dither, true);
#endif

    //water extinction
    bool isCameraInsideWater = CameraIsUnderwater.r > 0.0 && CausticsParameters.a > 0.0;
    if (isCameraInsideWater) outColor *= exp(-WATER_EXTINCTION_COEFFICIENTS * length(v_worldPos));

    vec3 projPos = v_clipPos.xyz / v_clipPos.w;
    applyVolumetricFog(outColor, projPos);

    //reflections
    bool isNeedSkyReflection = !isCameraInsideWater && (int(DimensionID.r) != 0);
    outColor += indirectSpecular(f0, worldDir, normal, mers.b, mers.r, v_ambientLight, isNeedSkyReflection);

    outColor = preExposeLighting(outColor, texture2D(s_PreviousFrameAverageLuminance, vec2_splat(0.5)).r);

    gl_FragColor = vec4(outColor, albedo.a);
#else
    gl_FragColor = albedo;
#endif //FORWARD_PBR_TRANSPARENT_PASS
}

#endif //BGFX_SHADER_TYPE_FRAGMENT
