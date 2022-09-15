#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
uniform vec4 CB0[58];
uniform vec4 CB1[216];
in vec4 POSITION;
in vec4 NORMAL;
in vec2 TEXCOORD0;
in vec2 TEXCOORD1;
in vec4 COLOR0;
in vec4 COLOR1;
out vec2 VARYING0;
out vec2 VARYING1;
out vec4 VARYING2;
out vec4 VARYING3;
out vec4 VARYING4;
out vec4 VARYING5;
out vec4 VARYING6;
out float VARYING7;

void main()
{
    vec3 v0 = (NORMAL.xyz * 0.0078740157186985015869140625) - vec3(1.0);
    int v1 = int(COLOR1.x) * 3;
    int v2 = v1 + 1;
    int v3 = v1 + 2;
    float v4 = dot(CB1[v1 * 1 + 0], POSITION);
    float v5 = dot(CB1[v2 * 1 + 0], POSITION);
    float v6 = dot(CB1[v3 * 1 + 0], POSITION);
    vec3 v7 = vec3(v4, v5, v6);
    vec3 v8 = vec3(dot(CB1[v1 * 1 + 0].xyz, v0), dot(CB1[v2 * 1 + 0].xyz, v0), dot(CB1[v3 * 1 + 0].xyz, v0));
    vec3 v9 = CB0[11].xyz - v7;
    vec3 v10 = -CB0[16].xyz;
    float v11 = dot(v8, v10);
    vec4 v12 = vec4(v4, v5, v6, 1.0);
    vec4 v13 = v12 * mat4(CB0[0], CB0[1], CB0[2], CB0[3]);
    vec3 v14 = ((v7 + (v8 * 6.0)).yxz * CB0[21].xyz) + CB0[22].xyz;
    vec4 v15 = vec4(0.0);
    v15.x = v14.x;
    vec4 v16 = v15;
    v16.y = v14.y;
    vec4 v17 = v16;
    v17.z = v14.z;
    vec4 v18 = v17;
    v18.w = 0.0;
    float v19 = COLOR1.y * 0.50359570980072021484375;
    float v20 = clamp(v11, 0.0, 1.0);
    vec3 v21 = (CB0[15].xyz * v20) + (CB0[17].xyz * clamp(-v11, 0.0, 1.0));
    vec4 v22 = vec4(0.0);
    v22.x = v21.x;
    vec4 v23 = v22;
    v23.y = v21.y;
    vec4 v24 = v23;
    v24.z = v21.z;
    vec4 v25 = v24;
    v25.w = (v20 * CB0[28].w) * (COLOR1.y * exp2((v19 * dot(v8, normalize(v10 + normalize(v9)))) - v19));
    vec4 v26 = vec4(dot(CB0[25], v12), dot(CB0[26], v12), dot(CB0[27], v12), 0.0);
    v26.w = COLOR1.z * 0.0039215688593685626983642578125;
    gl_Position = v13;
    VARYING0 = TEXCOORD0;
    VARYING1 = TEXCOORD1;
    VARYING2 = COLOR0;
    VARYING3 = v18;
    VARYING4 = vec4(v9, v13.w);
    VARYING5 = v25;
    VARYING6 = v26;
    VARYING7 = NORMAL.w;
}

