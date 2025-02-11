#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <EmitterParams.h>
uniform vec4 CB0[53];
uniform vec4 CB1[4];
uniform sampler2D depthTexTexture;
uniform sampler2D texTexture;

in vec3 VARYING0;
in vec4 VARYING1;
in vec4 VARYING3;
out vec4 _entryPointOutput;

void main()
{
    vec4 f0 = texture(texTexture, VARYING0.xy);
    float f1;
    do
    {
        if (0.0 == CB1[3].x)
        {
            f1 = clamp(VARYING3.w * abs((texture(depthTexTexture, VARYING3.xy).x * 500.0) - VARYING3.z), 0.0, 1.0);
            break;
        }
        else
        {
            f1 = 1.0;
            break;
        }
    } while(false);
    vec3 f2 = (f0.xyz + VARYING1.xyz) * CB1[0].xyz;
    vec4 f3 = vec4(0.0);
    f3.x = f2.x;
    vec4 f4 = f3;
    f4.y = f2.y;
    vec4 f5 = f4;
    f5.z = f2.z;
    vec3 f6 = sqrt(clamp((f5.xyz * f5.xyz) * CB0[15].y, vec3(0.0), vec3(1.0)));
    vec4 f7 = f5;
    f7.x = f6.x;
    vec4 f8 = f7;
    f8.y = f6.y;
    vec4 f9 = f8;
    f9.z = f6.z;
    float f10 = (f0.w * VARYING1.w) * (f1 * clamp(exp2((CB0[13].z * VARYING0.z) + CB0[13].x) - CB0[13].w, 0.0, 1.0));
    vec4 f11 = f9;
    f11.w = f10;
    vec4 f12 = f11;
    f12.w = f10;
    vec3 f13 = f12.xyz * f10;
    vec4 f14 = f12;
    f14.x = f13.x;
    vec4 f15 = f14;
    f15.y = f13.y;
    vec4 f16 = f15;
    f16.z = f13.z;
    _entryPointOutput = f16;
}

//$$depthTexTexture=s3
//$$texTexture=s0
