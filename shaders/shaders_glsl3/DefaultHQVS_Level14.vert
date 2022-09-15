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
in vec4 TEXCOORD4;
in vec4 TEXCOORD5;
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
    vec4 v1 = TEXCOORD5 * vec4(0.0039215688593685626983642578125);
    ivec4 v2 = ivec4(TEXCOORD4) * ivec4(3);
    float v3 = v1.x;
    float v4 = v1.y;
    float v5 = v1.z;
    float v6 = v1.w;
    vec4 v7 = (((CB1[v2.x * 1 + 0] * v3) + (CB1[v2.y * 1 + 0] * v4)) + (CB1[v2.z * 1 + 0] * v5)) + (CB1[v2.w * 1 + 0] * v6);
    ivec4 v8 = v2 + ivec4(1);
    vec4 v9 = (((CB1[v8.x * 1 + 0] * v3) + (CB1[v8.y * 1 + 0] * v4)) + (CB1[v8.z * 1 + 0] * v5)) + (CB1[v8.w * 1 + 0] * v6);
    ivec4 v10 = v2 + ivec4(2);
    vec4 v11 = (((CB1[v10.x * 1 + 0] * v3) + (CB1[v10.y * 1 + 0] * v4)) + (CB1[v10.z * 1 + 0] * v5)) + (CB1[v10.w * 1 + 0] * v6);
    float v12 = dot(v7, POSITION);
    float v13 = dot(v9, POSITION);
    float v14 = dot(v11, POSITION);
    vec3 v15 = vec3(v12, v13, v14);
    float v16 = dot(v7.xyz, v0);
    float v17 = dot(v9.xyz, v0);
    float v18 = dot(v11.xyz, v0);
    vec4 v19 = vec4(v12, v13, v14, 1.0) * mat4(CB0[0], CB0[1], CB0[2], CB0[3]);
    vec3 v20 = ((v15 + (vec3(v16, v17, v18) * 6.0)).yxz * CB0[21].xyz) + CB0[22].xyz;
    vec4 v21 = vec4(0.0);
    v21.x = v20.x;
    vec4 v22 = v21;
    v22.y = v20.y;
    vec4 v23 = v22;
    v23.z = v20.z;
    vec4 v24 = v23;
    v24.w = 0.0;
    vec4 v25 = vec4(v12, v13, v14, 0.0);
    v25.w = COLOR1.z * 0.0039215688593685626983642578125;
    vec4 v26 = vec4(v16, v17, v18, 0.0);
    v26.w = inversesqrt(0.1745329201221466064453125 * COLOR1.y);
    gl_Position = v19;
    VARYING0 = TEXCOORD0;
    VARYING1 = TEXCOORD1;
    VARYING2 = COLOR0;
    VARYING3 = v24;
    VARYING4 = vec4(CB0[11].xyz - v15, v19.w);
    VARYING5 = v26;
    VARYING6 = v25;
    VARYING7 = NORMAL.w;
}

