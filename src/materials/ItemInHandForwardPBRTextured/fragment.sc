$input v_clipPos
$input v_tangent
$input v_bitangent
$input v_normal
$input v_color0
$input v_absorbColor
$input v_scatterColor
$input v_pbrTextureId
$input v_prevWorldPos
$input v_texcoord0
$input v_worldPos

#include "bgfx_compute.sh"
#define MATERIAL_ITEM_IN_HAND_FORWARD_PBR_TEXTURED
#include "item_in_hand_forward.glsl"
