#version 150

#extension GL_ARB_shading_language_include : require
#include <RayFrame.h>
#include <Globals.h>
uniform vec4 CB4[2];
uniform vec4 CB0[53];
out vec2 _entryPointOutput;

void main()
{
    vec2 f0 = (CB4[0].zw * ((gl_FragCoord.xy * CB4[0].xy) - vec2(1.0))) + CB4[1].xy;
    vec3 f1 = normalize(((CB0[4].xyz * f0.x) + (CB0[5].xyz * f0.y)) - CB0[6].xyz);
    vec3 f2 = CB0[7].xyz * 0.00028000000747852027416229248046875;
    vec3 f3 = f2;
    f3.y = f2.y + 971.0;
    float f4 = dot(f1, f3);
    float f5 = 2.0 * f4;
    vec2 f6 = (vec2(f4 * (-2.0)) + sqrt(vec2(f5 * f5) - ((vec2(dot(f3, f3)) - vec2(946729.0, 951600.25)) * 4.0))) * 0.5;
    float f7 = f6.x;
    float f8 = f6.y - f7;
    vec3 f9 = (f2 + (f1 * f7)) + (f1 * f8);
    f9.y = 0.0;
    _entryPointOutput = vec2((length(f9 - f2) + f8) * 0.00200000009499490261077880859375, 0.14285714924335479736328125);
}

