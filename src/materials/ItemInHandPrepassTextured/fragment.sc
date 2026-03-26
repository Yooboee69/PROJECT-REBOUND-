$input v_color0
$input v_tangent
$input v_bitangent
$input v_normal
$input v_pbrTextureId
$input v_prevWorldPos
$input v_texcoord0
$input v_worldPos

#include "bgfx_compute.sh"
#define MATERIAL_ITEM_IN_HAND_PREPASS_TEXTURED
#if BGFX_SHADER_LANGUAGE_GLSL
precision highp int;
#endif
#include "item_in_hand_prepass.glsl"
