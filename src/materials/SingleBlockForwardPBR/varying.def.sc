vec4 a_color0 : COLOR0;
vec4 a_normal : NORMAL;
vec2 a_texcoord1 : TEXCOORD1;
int a_texcoord4 : TEXCOORD4;
vec3 a_position : POSITION;
vec4 a_tangent : TANGENT;
vec2 a_texcoord0 : TEXCOORD0;

vec4 i_data1 : TEXCOORD7;
vec4 i_data2 : TEXCOORD6;
vec4 i_data3 : TEXCOORD5;

vec4 v_color0 : COLOR0;
flat vec3 v_absorbColor : COLOR1;
flat vec3 v_scatterColor : COLOR2;
vec3 v_tangent : TANGENT;
vec3 v_bitangent : BITANGENT;
vec3 v_normal : NORMAL;
vec3 v_worldPos : TEXCOORD0;
vec4 v_clipPos : TEXCOORD1;
vec2 v_texcoord0 : TEXCOORD2;
vec2 v_lightmapUV : TEXCOORD3;
flat int v_pbrTextureId : TEXCOORD4;
