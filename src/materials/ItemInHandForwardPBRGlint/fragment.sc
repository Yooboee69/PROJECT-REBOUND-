$input v_clipPos
$input v_color0
$input v_glintUV
$input v_mers
$input v_absorbColor
$input v_scatterColor
$input v_normal
$input v_prevWorldPos
$input v_worldPos

#include "bgfx_shader.sh"

#define MATERIAL_ITEM_IN_HAND_FORWARD_PBR_GLINT
#include "item_in_hand_forward.glsl"
