$input v_color0
$input v_tangent
$input v_bitangent
$input v_normal
$input v_worldPos
$input v_texcoord0
$input v_pbrTextureId

#include "bgfx_compute.sh"

#define MATERIAL_SINGLE_BLOCK_PREPASS
#if BGFX_SHADER_LANGUAGE_GLSL
precision highp int;
#endif
#include "single_block_prepass.glsl"
