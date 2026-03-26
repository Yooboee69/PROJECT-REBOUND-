$input v_color0
$input v_tangent
$input v_bitangent
$input v_normal
$input v_worldPos
$input v_texcoord0
$input v_coloredLighting
$input v_vanillaLighting

#include "bgfx_shader.sh"
#if BGFX_SHADER_LANGUAGE_GLSL
precision highp int;
#endif
#include "particle_prepass.glsl"
