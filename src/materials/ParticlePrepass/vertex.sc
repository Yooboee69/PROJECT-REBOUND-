$input a_texcoord1
$input a_color0
$input a_normal
$input a_position
$input a_tangent
$input a_texcoord0

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
$output v_coloredLighting
$output v_vanillaLighting

#include "bgfx_shader.sh"
#include "particle_prepass.glsl"
