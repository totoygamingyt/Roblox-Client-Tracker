#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <LightShadowGPUTransform.h>
#include <Params.h>
uniform vec4 CB0[53];
uniform vec4 CB8[24];
uniform vec4 CB3[3];
uniform sampler2D ShadowAtlasTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube PrefilteredEnvTexture;
uniform sampler2D NormalMap1Texture;
uniform sampler2D NormalMap2Texture;

in vec4 VARYING0;
in vec3 VARYING1;
in vec2 VARYING2;
in vec2 VARYING3;
in vec2 VARYING4;
in vec3 VARYING5;
in vec4 VARYING6;
in vec4 VARYING7;
out vec4 _entryPointOutput;

void main()
{
    vec3 f0 = CB0[7].xyz - VARYING7.xyz;
    vec3 f1 = -CB0[11].xyz;
    float f2 = clamp(dot(step(CB0[19].xyz, abs(VARYING5 - CB0[18].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f3 = VARYING5.yzx - (VARYING5.yzx * f2);
    vec4 f4 = vec4(clamp(f2, 0.0, 1.0));
    vec4 f5 = mix(texture(LightMapTexture, f3), vec4(0.0), f4);
    vec4 f6 = mix(texture(LightGridSkylightTexture, f3), vec4(1.0), f4);
    vec3 f7 = f5.xyz * (f5.w * 120.0);
    float f8 = f6.x;
    float f9 = f6.y;
    vec3 f10 = f0 - CB0[41].xyz;
    vec3 f11 = f0 - CB0[42].xyz;
    vec3 f12 = f0 - CB0[43].xyz;
    vec4 f13 = vec4(f0, 1.0) * mat4(CB8[((dot(f10, f10) < CB0[41].w) ? 0 : ((dot(f11, f11) < CB0[42].w) ? 1 : ((dot(f12, f12) < CB0[43].w) ? 2 : 3))) * 4 + 0], CB8[((dot(f10, f10) < CB0[41].w) ? 0 : ((dot(f11, f11) < CB0[42].w) ? 1 : ((dot(f12, f12) < CB0[43].w) ? 2 : 3))) * 4 + 1], CB8[((dot(f10, f10) < CB0[41].w) ? 0 : ((dot(f11, f11) < CB0[42].w) ? 1 : ((dot(f12, f12) < CB0[43].w) ? 2 : 3))) * 4 + 2], CB8[((dot(f10, f10) < CB0[41].w) ? 0 : ((dot(f11, f11) < CB0[42].w) ? 1 : ((dot(f12, f12) < CB0[43].w) ? 2 : 3))) * 4 + 3]);
    vec4 f14 = textureLod(ShadowAtlasTexture, f13.xy, 0.0);
    vec2 f15 = vec2(0.0);
    f15.x = CB0[46].z;
    vec2 f16 = f15;
    f16.y = CB0[46].w;
    float f17 = (2.0 * f13.z) - 1.0;
    float f18 = exp(CB0[46].z * f17);
    float f19 = -exp((-CB0[46].w) * f17);
    vec2 f20 = (f16 * CB0[47].y) * vec2(f18, f19);
    vec2 f21 = f20 * f20;
    float f22 = f14.x;
    float f23 = max(f14.y - (f22 * f22), f21.x);
    float f24 = f18 - f22;
    float f25 = f14.z;
    float f26 = max(f14.w - (f25 * f25), f21.y);
    float f27 = f19 - f25;
    float f28 = ((dot(VARYING6.xyz, f1) * CB0[47].x) > 0.0) ? mix(min((f18 <= f22) ? 1.0 : clamp(((f23 / (f23 + (f24 * f24))) - 0.20000000298023223876953125) * 1.25, 0.0, 1.0), (f19 <= f25) ? 1.0 : clamp(((f26 / (f26 + (f27 * f27))) - 0.20000000298023223876953125) * 1.25, 0.0, 1.0)), f9, clamp((length(f0 - CB0[7].xyz) * CB0[46].y) - (CB0[46].x * CB0[46].y), 0.0, 1.0)) : f9;
    vec4 f29 = vec4(CB3[0].w);
    vec4 f30 = ((mix(texture(NormalMap1Texture, VARYING2), texture(NormalMap2Texture, VARYING2), f29) * VARYING0.x) + (mix(texture(NormalMap1Texture, VARYING3), texture(NormalMap2Texture, VARYING3), f29) * VARYING0.y)) + (mix(texture(NormalMap1Texture, VARYING4), texture(NormalMap2Texture, VARYING4), f29) * VARYING0.z);
    vec2 f31 = f30.wy * 2.0;
    vec2 f32 = f31 - vec2(1.0);
    float f33 = f30.x;
    vec3 f34 = vec3(dot(VARYING1, VARYING0.xyz));
    vec3 f35 = vec4(normalize(((mix(vec3(VARYING6.z, 0.0, -VARYING6.x), vec3(-VARYING6.y, VARYING6.x, 0.0), f34) * f32.x) + (mix(vec3(0.0, 1.0, 0.0), vec3(0.0, -VARYING6.z, VARYING6.y), f34) * f32.y)) + (VARYING6.xyz * sqrt(clamp(1.0 + dot(vec2(1.0) - f31, f32), 0.0, 1.0)))), f33).xyz;
    vec3 f36 = mix(VARYING6.xyz, f35, vec3(0.25));
    vec3 f37 = normalize(VARYING7.xyz);
    vec3 f38 = f35 * f35;
    bvec3 f39 = lessThan(f35, vec3(0.0));
    vec3 f40 = vec3(f39.x ? f38.x : vec3(0.0).x, f39.y ? f38.y : vec3(0.0).y, f39.z ? f38.z : vec3(0.0).z);
    vec3 f41 = f38 - f40;
    float f42 = f41.x;
    float f43 = f41.y;
    float f44 = f41.z;
    float f45 = f40.x;
    float f46 = f40.y;
    float f47 = f40.z;
    vec3 f48 = -f37;
    vec3 f49 = reflect(f48, f36);
    vec3 f50 = normalize(f1 + f37);
    float f51 = f33 * f33;
    float f52 = max(0.001000000047497451305389404296875, dot(f35, f50));
    float f53 = dot(f1, f50);
    float f54 = 1.0 - f53;
    float f55 = f54 * f54;
    float f56 = (f55 * f55) * f54;
    float f57 = f51 * f51;
    float f58 = (((f52 * f57) - f52) * f52) + 1.0;
    vec3 f59 = mix(((min(f7 + (CB0[27].xyz + ((CB0[28].xyz * (2.0 - CB0[9].w)) * f8)), vec3(CB0[16].w)) + (((((((CB0[35].xyz * f42) + (CB0[37].xyz * f43)) + (CB0[39].xyz * f44)) + (CB0[36].xyz * f45)) + (CB0[38].xyz * f46)) + (CB0[40].xyz * f47)) + (((((((CB0[29].xyz * f42) + (CB0[31].xyz * f43)) + (CB0[33].xyz * f44)) + (CB0[30].xyz * f45)) + (CB0[32].xyz * f46)) + (CB0[34].xyz * f47)) * f8))) + (CB0[10].xyz * f28)) * CB3[1].xyz, ((textureLod(PrefilteredEnvTexture, vec4(f49, 0.0).xyz, 0.0).xyz * mix(CB0[26].xyz, CB0[25].xyz, vec3(clamp(f49.y * 1.58823525905609130859375, 0.0, 1.0)))) * f8) + (f7 * 0.100000001490116119384765625), vec3(((clamp(0.7799999713897705078125 - (2.5 * abs(dot(f36, f37))), 0.0, 1.0) + 0.300000011920928955078125) * VARYING0.w) * CB3[2].z)) + (((((vec3(f56) + (vec3(0.0199999995529651641845703125) * (1.0 - f56))) * (((f57 + (f57 * f57)) / (((f58 * f58) * ((f53 * 3.0) + 0.5)) * ((f52 * 0.75) + 0.25))) * clamp((dot(f35, f1) * CB0[9].w) * f28, 0.0, 1.0))) * CB0[10].xyz) * (CB0[9].w * CB0[9].w)) * clamp(1.0 - (VARYING7.w * CB0[23].y), 0.0, 1.0));
    vec4 f60 = vec4(0.0);
    f60.x = f59.x;
    vec4 f61 = f60;
    f61.y = f59.y;
    vec4 f62 = f61;
    f62.z = f59.z;
    vec4 f63 = f62;
    f63.w = 1.0;
    vec3 f64 = textureLod(PrefilteredEnvTexture, vec4(f48, 0.0).xyz, max(CB0[13].y, VARYING6.w) * 5.0).xyz;
    bvec3 f65 = bvec3(!(CB0[13].w == 0.0));
    vec3 f66 = mix(vec3(f65.x ? CB0[14].xyz.x : f64.x, f65.y ? CB0[14].xyz.y : f64.y, f65.z ? CB0[14].xyz.z : f64.z), f63.xyz, vec3(VARYING6.w));
    vec4 f67 = f63;
    f67.x = f66.x;
    vec4 f68 = f67;
    f68.y = f66.y;
    vec4 f69 = f68;
    f69.z = f66.z;
    vec3 f70 = sqrt(clamp(f69.xyz * CB0[15].y, vec3(0.0), vec3(1.0)));
    vec4 f71 = f69;
    f71.x = f70.x;
    vec4 f72 = f71;
    f72.y = f70.y;
    vec4 f73 = f72;
    f73.z = f70.z;
    _entryPointOutput = f73;
}

//$$ShadowAtlasTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$PrefilteredEnvTexture=s15
//$$NormalMap1Texture=s0
//$$NormalMap2Texture=s2
