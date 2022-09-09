#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <LightShadowGPUTransform.h>
#include <MaterialParams.h>
uniform vec4 CB0[58];
uniform vec4 CB8[24];
uniform vec4 CB2[4];
uniform sampler2D ShadowAtlasTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube PrefilteredEnvTexture;
uniform samplerCube PrefilteredEnvIndoorTexture;
uniform samplerCube PrefilteredEnvBlendTargetTexture;
uniform sampler2D PrecomputedBRDFTexture;
uniform sampler2D DiffuseMapTexture;
uniform sampler2D NormalMapTexture;
uniform sampler2D NormalDetailMapTexture;

in vec2 VARYING0;
in vec2 VARYING1;
in vec4 VARYING2;
in vec4 VARYING3;
in vec4 VARYING4;
in vec4 VARYING5;
in vec4 VARYING6;
in vec4 VARYING7;
in float VARYING8;
out vec4 _entryPointOutput;

void main()
{
    float f0 = length(VARYING4.xyz);
    vec3 f1 = VARYING4.xyz / vec3(f0);
    vec2 f2 = VARYING1;
    f2.y = (fract(VARYING1.y) + VARYING8) * 0.25;
    float f3 = clamp(1.0 - (VARYING4.w * CB0[28].y), 0.0, 1.0);
    vec4 f4 = texture(NormalMapTexture, f2);
    vec2 f5 = f4.wy * 2.0;
    vec2 f6 = f5 - vec2(1.0);
    float f7 = sqrt(clamp(1.0 + dot(vec2(1.0) - f5, f6), 0.0, 1.0));
    vec3 f8 = vec3(f6, f7);
    vec2 f9 = f8.xy + (vec3((texture(NormalDetailMapTexture, VARYING0 * CB2[0].x).wy * 2.0) - vec2(1.0), 0.0).xy * (clamp(VARYING2.w - 0.5, 0.0, 1.0) * clamp(1.0 - (2.0 * VARYING7.w), 0.0, 1.0)));
    vec3 f10 = f8;
    f10.x = f9.x;
    vec3 f11 = f10;
    f11.y = f9.y;
    vec2 f12 = f11.xy * (f3 * CB2[3].w);
    vec4 f13 = vec4(VARYING2.xyz * (texture(DiffuseMapTexture, f2).x * 2.0), VARYING2.w);
    float f14 = gl_FrontFacing ? 1.0 : (-1.0);
    vec3 f15 = VARYING6.xyz * f14;
    vec3 f16 = VARYING5.xyz * f14;
    vec3 f17 = normalize(((f15 * f12.x) + (cross(f16, f15) * f12.y)) + (f16 * f7));
    vec3 f18 = -CB0[16].xyz;
    float f19 = dot(f17, f18);
    vec3 f20 = f13.xyz;
    vec3 f21 = f20 * f20;
    vec4 f22 = f13;
    f22.x = f21.x;
    vec4 f23 = f22;
    f23.y = f21.y;
    vec4 f24 = f23;
    f24.z = f21.z;
    vec3 f25 = VARYING7.xyz - (CB0[16].xyz * VARYING3.w);
    float f26 = clamp(dot(step(CB0[24].xyz, abs(VARYING3.xyz - CB0[23].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f27 = VARYING3.yzx - (VARYING3.yzx * f26);
    vec4 f28 = texture(LightMapTexture, f27);
    vec4 f29 = texture(LightGridSkylightTexture, f27);
    vec4 f30 = vec4(clamp(f26, 0.0, 1.0));
    vec4 f31 = mix(f28, vec4(0.0), f30);
    vec4 f32 = mix(f29, vec4(1.0), f30);
    float f33 = f32.x;
    float f34 = f32.y;
    vec3 f35 = f25 - CB0[46].xyz;
    vec3 f36 = f25 - CB0[47].xyz;
    vec3 f37 = f25 - CB0[48].xyz;
    vec4 f38 = vec4(f25, 1.0) * mat4(CB8[((dot(f35, f35) < CB0[46].w) ? 0 : ((dot(f36, f36) < CB0[47].w) ? 1 : ((dot(f37, f37) < CB0[48].w) ? 2 : 3))) * 4 + 0], CB8[((dot(f35, f35) < CB0[46].w) ? 0 : ((dot(f36, f36) < CB0[47].w) ? 1 : ((dot(f37, f37) < CB0[48].w) ? 2 : 3))) * 4 + 1], CB8[((dot(f35, f35) < CB0[46].w) ? 0 : ((dot(f36, f36) < CB0[47].w) ? 1 : ((dot(f37, f37) < CB0[48].w) ? 2 : 3))) * 4 + 2], CB8[((dot(f35, f35) < CB0[46].w) ? 0 : ((dot(f36, f36) < CB0[47].w) ? 1 : ((dot(f37, f37) < CB0[48].w) ? 2 : 3))) * 4 + 3]);
    vec4 f39 = textureLod(ShadowAtlasTexture, f38.xy, 0.0);
    vec2 f40 = vec2(0.0);
    f40.x = CB0[51].z;
    vec2 f41 = f40;
    f41.y = CB0[51].w;
    float f42 = (2.0 * f38.z) - 1.0;
    float f43 = exp(CB0[51].z * f42);
    float f44 = -exp((-CB0[51].w) * f42);
    vec2 f45 = (f41 * CB0[52].y) * vec2(f43, f44);
    vec2 f46 = f45 * f45;
    float f47 = f39.x;
    float f48 = max(f39.y - (f47 * f47), f46.x);
    float f49 = f43 - f47;
    float f50 = f39.z;
    float f51 = max(f39.w - (f50 * f50), f46.y);
    float f52 = f44 - f50;
    float f53 = CB0[31].w * f3;
    float f54 = 0.08900000154972076416015625 + (CB2[0].y * 0.9110000133514404296875);
    vec3 f55 = reflect(-f1, f17);
    vec3 f56 = normalize(f1 - CB0[16].xyz);
    float f57 = clamp((f19 * CB0[14].w) * (((f19 * CB0[52].x) > 0.0) ? mix(min((f43 <= f47) ? 1.0 : clamp(((f48 / (f48 + (f49 * f49))) - 0.20000000298023223876953125) * 1.25, 0.0, 1.0), (f44 <= f50) ? 1.0 : clamp(((f51 / (f51 + (f52 * f52))) - 0.20000000298023223876953125) * 1.25, 0.0, 1.0)), f34, clamp((length(f25 - CB0[11].xyz) * CB0[51].y) - (CB0[51].x * CB0[51].y), 0.0, 1.0)) : f34), 0.0, 1.0);
    float f58 = f54 * f54;
    float f59 = max(0.001000000047497451305389404296875, dot(f17, f56));
    float f60 = dot(f18, f56);
    float f61 = 1.0 - f60;
    float f62 = f61 * f61;
    float f63 = (f62 * f62) * f61;
    vec3 f64 = vec3(f63) + (vec3(0.039999999105930328369140625) * (1.0 - f63));
    float f65 = f58 * f58;
    float f66 = (((f59 * f65) - f59) * f59) + 1.0;
    float f67 = f54 * 5.0;
    vec3 f68 = vec4(f55, f67).xyz;
    vec3 f69 = textureLod(PrefilteredEnvIndoorTexture, f68, f67).xyz;
    vec3 f70;
    if (CB0[32].w == 0.0)
    {
        f70 = f69;
    }
    else
    {
        f70 = mix(f69, textureLod(PrefilteredEnvBlendTargetTexture, f68, f67).xyz, vec3(CB0[32].w));
    }
    vec4 f71 = texture(PrecomputedBRDFTexture, vec2(f54, max(9.9999997473787516355514526367188e-05, dot(f17, f1))));
    float f72 = f71.x;
    float f73 = f71.y;
    vec3 f74 = ((vec3(0.039999999105930328369140625) * f72) + vec3(f73)) / vec3(f72 + f73);
    vec3 f75 = f17 * f17;
    bvec3 f76 = lessThan(f17, vec3(0.0));
    vec3 f77 = vec3(f76.x ? f75.x : vec3(0.0).x, f76.y ? f75.y : vec3(0.0).y, f76.z ? f75.z : vec3(0.0).z);
    vec3 f78 = f75 - f77;
    float f79 = f78.x;
    float f80 = f78.y;
    float f81 = f78.z;
    float f82 = f77.x;
    float f83 = f77.y;
    float f84 = f77.z;
    vec3 f85 = (((((((vec3(1.0) - (f64 * f53)) * CB0[15].xyz) * f57) + ((f31.xyz * (f31.w * 120.0)) * 1.0)) + ((vec3(1.0) - (f74 * f53)) * (((((((CB0[40].xyz * f79) + (CB0[42].xyz * f80)) + (CB0[44].xyz * f81)) + (CB0[41].xyz * f82)) + (CB0[43].xyz * f83)) + (CB0[45].xyz * f84)) + (((((((CB0[34].xyz * f79) + (CB0[36].xyz * f80)) + (CB0[38].xyz * f81)) + (CB0[35].xyz * f82)) + (CB0[37].xyz * f83)) + (CB0[39].xyz * f84)) * f33)))) + (CB0[32].xyz + ((CB0[33].xyz * (2.0 - CB0[14].w)) * f33))) * f24.xyz) + ((((f64 * (((f65 + (f65 * f65)) / (((f66 * f66) * ((f60 * 3.0) + 0.5)) * ((f59 * 0.75) + 0.25))) * f57)) * CB0[15].xyz) * (CB0[14].w * CB0[14].w)) + ((mix(f70, textureLod(PrefilteredEnvTexture, f68, f67).xyz * mix(CB0[31].xyz, CB0[30].xyz, vec3(clamp(f55.y * 1.58823525905609130859375, 0.0, 1.0))), vec3(f33)) * f74) * f53));
    vec4 f86 = vec4(0.0);
    f86.x = f85.x;
    vec4 f87 = f86;
    f87.y = f85.y;
    vec4 f88 = f87;
    f88.z = f85.z;
    vec4 f89 = f88;
    f89.w = VARYING2.w;
    float f90 = clamp(exp2((CB0[18].z * f0) + CB0[18].x) - CB0[18].w, 0.0, 1.0);
    vec3 f91 = textureLod(PrefilteredEnvTexture, vec4(-VARYING4.xyz, 0.0).xyz, max(CB0[18].y, f90) * 5.0).xyz;
    bvec3 f92 = bvec3(!(CB0[18].w == 0.0));
    vec3 f93 = mix(vec3(f92.x ? CB0[19].xyz.x : f91.x, f92.y ? CB0[19].xyz.y : f91.y, f92.z ? CB0[19].xyz.z : f91.z), f89.xyz, vec3(f90));
    vec4 f94 = f89;
    f94.x = f93.x;
    vec4 f95 = f94;
    f95.y = f93.y;
    vec4 f96 = f95;
    f96.z = f93.z;
    vec3 f97 = sqrt(clamp(f96.xyz * CB0[20].y, vec3(0.0), vec3(1.0))) + vec3((-0.00048828125) + (0.0009765625 * fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))))));
    vec4 f98 = f96;
    f98.x = f97.x;
    vec4 f99 = f98;
    f99.y = f97.y;
    vec4 f100 = f99;
    f100.z = f97.z;
    vec4 f101 = f100;
    f101.w = VARYING2.w;
    _entryPointOutput = f101;
}

//$$ShadowAtlasTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$PrefilteredEnvTexture=s15
//$$PrefilteredEnvIndoorTexture=s14
//$$PrefilteredEnvBlendTargetTexture=s2
//$$PrecomputedBRDFTexture=s11
//$$DiffuseMapTexture=s3
//$$NormalMapTexture=s4
//$$NormalDetailMapTexture=s8
