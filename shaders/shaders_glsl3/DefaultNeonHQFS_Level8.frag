#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
uniform vec4 CB0[58];
uniform samplerCube PrefilteredEnvTexture;

in vec4 VARYING2;
in vec4 VARYING4;
out vec4 _entryPointOutput;

void main()
{
    vec4 f0 = vec4(0.0);
    f0.x = VARYING2.x;
    vec4 f1 = f0;
    f1.y = VARYING2.y;
    vec4 f2 = f1;
    f2.z = VARYING2.z;
    vec3 f3 = pow(f2.xyz * 1.35000002384185791015625, vec3(4.0)) * 4.0;
    vec4 f4 = f2;
    f4.x = f3.x;
    vec4 f5 = f4;
    f5.y = f3.y;
    vec4 f6 = f5;
    f6.z = f3.z;
    float f7 = clamp(exp2((CB0[18].z * length(VARYING4.xyz)) + CB0[18].x) - CB0[18].w, 0.0, 1.0);
    vec3 f8 = textureLod(PrefilteredEnvTexture, vec4(-VARYING4.xyz, 0.0).xyz, max(CB0[18].y, f7) * 5.0).xyz;
    bvec3 f9 = bvec3(!(CB0[18].w == 0.0));
    vec3 f10 = mix(vec3(f9.x ? CB0[19].xyz.x : f8.x, f9.y ? CB0[19].xyz.y : f8.y, f9.z ? CB0[19].xyz.z : f8.z), f6.xyz, vec3(f7));
    vec4 f11 = f6;
    f11.x = f10.x;
    vec4 f12 = f11;
    f12.y = f10.y;
    vec4 f13 = f12;
    f13.z = f10.z;
    vec3 f14 = sqrt(clamp(f13.xyz * CB0[20].y, vec3(0.0), vec3(1.0))) + vec3((-0.00048828125) + (0.0009765625 * fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))))));
    vec4 f15 = f13;
    f15.x = f14.x;
    vec4 f16 = f15;
    f16.y = f14.y;
    vec4 f17 = f16;
    f17.z = f14.z;
    vec4 f18 = f17;
    f18.w = 1.0 - (clamp(f7, 0.0, 1.0) * VARYING2.w);
    _entryPointOutput = f18;
}

//$$PrefilteredEnvTexture=s15
