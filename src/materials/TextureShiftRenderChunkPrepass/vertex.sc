$input a_color0
$input a_texcoord1
$input a_normal
$input a_position
$input a_tangent
$input a_texcoord0
$input a_texcoord2

#if INSTANCING__ON
$input i_data1
$input i_data2
$input i_data3
#endif

$output v_color0
$output v_tangent
$output v_bitangent
$output v_normal
$output v_worldPos
$output v_texcoord0
$output v_lightmapUV
$output v_lightColor
$output v_textureShift

#include "bgfx_shader.sh"

#define MATERIAL_TEXTURE_SHIFT_RENDERCHUNK_PREPASS
#include "texture_shift_renderchunk_prepass.glsl"
