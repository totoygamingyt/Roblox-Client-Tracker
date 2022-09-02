#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
uniform vec4 CB1[216];
uniform vec4 CB0[53];
in vec4 POSITION;
in vec2 TEXCOORD0;
in vec4 TEXCOORD4;
in vec4 TEXCOORD5;
out vec2 VARYING0;

void main()
{
    vec4 v0 = TEXCOORD5 * vec4(0.0039215688593685626983642578125);
    ivec4 v1 = ivec4(TEXCOORD4) * ivec4(3);
    float v2 = v0.x;
    float v3 = v0.y;
    float v4 = v0.z;
    float v5 = v0.w;
    ivec4 v6 = v1 + ivec4(1);
    ivec4 v7 = v1 + ivec4(2);
    gl_Position = vec4(dot((((CB1[v1.x * 1 + 0] * v2) + (CB1[v1.y * 1 + 0] * v3)) + (CB1[v1.z * 1 + 0] * v4)) + (CB1[v1.w * 1 + 0] * v5), POSITION), dot((((CB1[v6.x * 1 + 0] * v2) + (CB1[v6.y * 1 + 0] * v3)) + (CB1[v6.z * 1 + 0] * v4)) + (CB1[v6.w * 1 + 0] * v5), POSITION), dot((((CB1[v7.x * 1 + 0] * v2) + (CB1[v7.y * 1 + 0] * v3)) + (CB1[v7.z * 1 + 0] * v4)) + (CB1[v7.w * 1 + 0] * v5), POSITION), 1.0) * mat4(CB0[0], CB0[1], CB0[2], CB0[3]);
    VARYING0 = TEXCOORD0;
}

