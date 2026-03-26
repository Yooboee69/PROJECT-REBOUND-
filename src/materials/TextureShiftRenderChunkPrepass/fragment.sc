$input v_color0
$input v_tangent
$input v_bitangent
$input v_normal
$input v_worldPos
$input v_texcoord0
$input v_lightmapUV
$input v_lightColor
$input v_textureShift

#include "bgfx_compute.sh"

#define MATERIAL_TEXTURE_SHIFT_RENDERCHUNK_PREPASS

#if BGFX_SHADER_LANGUAGE_GLSL
precision highp int;
#endif
#include "texture_shift_renderchunk_prepass.glsl"
