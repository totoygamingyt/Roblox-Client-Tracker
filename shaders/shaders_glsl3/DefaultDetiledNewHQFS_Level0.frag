#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <MaterialParams.h>
uniform vec4 CB0[58];
uniform vec4 CB2[4];
uniform sampler2D ShadowMapTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube PrefilteredEnvTexture;
uniform samplerCube PrefilteredEnvIndoorTexture;
uniform samplerCube PrefilteredEnvBlendTargetTexture;
uniform sampler2D PrecomputedBRDFTexture;
uniform sampler2D NoiseMapTexture;
uniform sampler2D DiffuseMapTexture;
uniform sampler2D NormalMapTexture;
uniform sampler2D NormalDetailMapTexture;
uniform sampler2D SpecularMapTexture;

in vec2 VARYING0;
in vec4 VARYING2;
in vec4 VARYING3;
in vec4 VARYING4;
in vec4 VARYING5;
in vec4 VARYING6;
in vec4 VARYING7;
out vec4 _entryPointOutput;

void main()
{
    float f0 = length(VARYING4.xyz);
    vec3 f1 = VARYING4.xyz / vec3(f0);
    float f2 = clamp(1.0 - (VARYING4.w * CB0[28].y), 0.0, 1.0);
    vec4 f3 = texture(NoiseMapTexture, VARYING0 * CB2[2].w);
    float f4 = f3.x * 8.0;
    float f5 = fract(f4);
    float f6 = floor(f4);
    vec2 f7 = dFdx(VARYING0);
    vec2 f8 = dFdy(VARYING0);
    vec2 f9 = sin(vec2(3.0, 7.0) * f6) + VARYING0;
    vec2 f10 = sin(vec2(3.0, 7.0) * (f6 + 1.0)) + VARYING0;
    vec4 f11 = vec4(f5);
    vec4 f12 = mix(textureGrad(DiffuseMapTexture, f9, f7, f8), textureGrad(DiffuseMapTexture, f10, f7, f8), f11);
    vec2 f13 = textureGrad(NormalMapTexture, f9, f7, f8).wy * 2.0;
    vec2 f14 = f13 - vec2(1.0);
    vec4 f15 = vec4(0.0);
    f15.x = f14.x;
    vec4 f16 = f15;
    f16.y = f14.y;
    vec4 f17 = f16;
    f17.z = sqrt(clamp(1.0 + dot(vec2(1.0) - f13, f14), 0.0, 1.0));
    vec2 f18 = textureGrad(NormalMapTexture, f10, f7, f8).wy * 2.0;
    vec2 f19 = f18 - vec2(1.0);
    vec4 f20 = vec4(0.0);
    f20.x = f19.x;
    vec4 f21 = f20;
    f21.y = f19.y;
    vec4 f22 = f21;
    f22.z = sqrt(clamp(1.0 + dot(vec2(1.0) - f18, f19), 0.0, 1.0));
    vec3 f23 = mix(f17.xyz, f22.xyz, vec3(f5));
    vec2 f24 = f23.xy + (vec3((texture(NormalDetailMapTexture, VARYING0 * CB2[0].w).wy * 2.0) - vec2(1.0), 0.0).xy * CB2[1].x);
    vec3 f25 = f23;
    f25.x = f24.x;
    vec3 f26 = f25;
    f26.y = f24.y;
    vec2 f27 = f26.xy * f2;
    float f28 = f27.x;
    vec4 f29 = mix(textureGrad(SpecularMapTexture, f9, f7, f8), textureGrad(SpecularMapTexture, f10, f7, f8), f11);
    vec4 f30 = vec4((mix(vec3(1.0), VARYING2.xyz, vec3(mix(1.0, f12.w, CB2[3].w))) * f12.xyz) * (1.0 + (f28 * 0.20000000298023223876953125)), VARYING2.w);
    float f31 = gl_FrontFacing ? 1.0 : (-1.0);
    vec3 f32 = VARYING6.xyz * f31;
    vec3 f33 = VARYING5.xyz * f31;
    vec3 f34 = normalize(((f32 * f28) + (cross(f33, f32) * f27.y)) + (f33 * f23.z));
    vec3 f35 = f30.xyz;
    vec3 f36 = f35 * f35;
    vec4 f37 = f30;
    f37.x = f36.x;
    vec4 f38 = f37;
    f38.y = f36.y;
    vec4 f39 = f38;
    f39.z = f36.z;
    float f40 = CB0[31].w * f2;
    float f41 = 0.08900000154972076416015625 + (f29.y * 0.9110000133514404296875);
    vec3 f42 = reflect(-f1, f34);
    float f43 = f29.x * f40;
    vec3 f44 = mix(vec3(0.039999999105930328369140625), f39.xyz, vec3(f43));
    vec3 f45 = VARYING7.xyz - (CB0[16].xyz * VARYING3.w);
    float f46 = clamp(dot(step(CB0[24].xyz, abs(VARYING3.xyz - CB0[23].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f47 = VARYING3.yzx - (VARYING3.yzx * f46);
    vec4 f48 = texture(LightMapTexture, f47);
    vec4 f49 = texture(LightGridSkylightTexture, f47);
    vec4 f50 = vec4(clamp(f46, 0.0, 1.0));
    vec4 f51 = mix(f48, vec4(0.0), f50);
    vec4 f52 = mix(f49, vec4(1.0), f50);
    float f53 = f52.x;
    vec4 f54 = texture(ShadowMapTexture, f45.xy);
    float f55 = f45.z;
    vec3 f56 = -CB0[16].xyz;
    float f57 = (dot(f34, f56) * CB0[14].w) * ((1.0 - ((step(f54.x, f55) * clamp(CB0[29].z + (CB0[29].w * abs(f55 - 0.5)), 0.0, 1.0)) * f54.y)) * f52.y);
    vec3 f58 = normalize(f1 - CB0[16].xyz);
    float f59 = clamp(f57, 0.0, 1.0);
    float f60 = f41 * f41;
    float f61 = max(0.001000000047497451305389404296875, dot(f34, f58));
    float f62 = dot(f56, f58);
    float f63 = 1.0 - f62;
    float f64 = f63 * f63;
    float f65 = (f64 * f64) * f63;
    vec3 f66 = vec3(f65) + (f44 * (1.0 - f65));
    float f67 = f60 * f60;
    float f68 = (((f61 * f67) - f61) * f61) + 1.0;
    float f69 = 1.0 - f43;
    float f70 = f40 * f69;
    vec3 f71 = vec3(f69);
    float f72 = f41 * 5.0;
    vec3 f73 = vec4(f42, f72).xyz;
    vec3 f74 = textureLod(PrefilteredEnvIndoorTexture, f73, f72).xyz;
    vec3 f75;
    if (CB0[32].w == 0.0)
    {
        f75 = f74;
    }
    else
    {
        f75 = mix(f74, textureLod(PrefilteredEnvBlendTargetTexture, f73, f72).xyz, vec3(CB0[32].w));
    }
    vec4 f76 = texture(PrecomputedBRDFTexture, vec2(f41, max(9.9999997473787516355514526367188e-05, dot(f34, f1))));
    float f77 = f76.x;
    float f78 = f76.y;
    vec3 f79 = ((f44 * f77) + vec3(f78)) / vec3(f77 + f78);
    vec3 f80 = f34 * f34;
    bvec3 f81 = lessThan(f34, vec3(0.0));
    vec3 f82 = vec3(f81.x ? f80.x : vec3(0.0).x, f81.y ? f80.y : vec3(0.0).y, f81.z ? f80.z : vec3(0.0).z);
    vec3 f83 = f80 - f82;
    float f84 = f83.x;
    float f85 = f83.y;
    float f86 = f83.z;
    float f87 = f82.x;
    float f88 = f82.y;
    float f89 = f82.z;
    vec3 f90 = ((((((f51.xyz * (f51.w * 120.0)) * 1.0) + ((((f71 - (f66 * f70)) * CB0[15].xyz) * f59) + (CB0[17].xyz * (f69 * clamp(-f57, 0.0, 1.0))))) + ((f71 - (f79 * f70)) * (((((((CB0[40].xyz * f84) + (CB0[42].xyz * f85)) + (CB0[44].xyz * f86)) + (CB0[41].xyz * f87)) + (CB0[43].xyz * f88)) + (CB0[45].xyz * f89)) + (((((((CB0[34].xyz * f84) + (CB0[36].xyz * f85)) + (CB0[38].xyz * f86)) + (CB0[35].xyz * f87)) + (CB0[37].xyz * f88)) + (CB0[39].xyz * f89)) * f53)))) + (CB0[32].xyz + ((CB0[33].xyz * (2.0 - CB0[14].w)) * f53))) * f39.xyz) + ((((f66 * (((f67 + (f67 * f67)) / (((f68 * f68) * ((f62 * 3.0) + 0.5)) * ((f61 * 0.75) + 0.25))) * f59)) * CB0[15].xyz) * (CB0[14].w * CB0[14].w)) + ((mix(f75, textureLod(PrefilteredEnvTexture, f73, f72).xyz * mix(CB0[31].xyz, CB0[30].xyz, vec3(clamp(f42.y * 1.58823525905609130859375, 0.0, 1.0))), vec3(f53)) * f79) * f40));
    vec4 f91 = vec4(0.0);
    f91.x = f90.x;
    vec4 f92 = f91;
    f92.y = f90.y;
    vec4 f93 = f92;
    f93.z = f90.z;
    vec4 f94 = f93;
    f94.w = VARYING2.w;
    float f95 = clamp(exp2((CB0[18].z * f0) + CB0[18].x) - CB0[18].w, 0.0, 1.0);
    vec3 f96 = textureLod(PrefilteredEnvTexture, vec4(-VARYING4.xyz, 0.0).xyz, max(CB0[18].y, f95) * 5.0).xyz;
    bvec3 f97 = bvec3(!(CB0[18].w == 0.0));
    vec3 f98 = mix(vec3(f97.x ? CB0[19].xyz.x : f96.x, f97.y ? CB0[19].xyz.y : f96.y, f97.z ? CB0[19].xyz.z : f96.z), f94.xyz, vec3(f95));
    vec4 f99 = f94;
    f99.x = f98.x;
    vec4 f100 = f99;
    f100.y = f98.y;
    vec4 f101 = f100;
    f101.z = f98.z;
    vec3 f102 = sqrt(clamp(f101.xyz * CB0[20].y, vec3(0.0), vec3(1.0))) + vec3((-0.00048828125) + (0.0009765625 * fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))))));
    vec4 f103 = f101;
    f103.x = f102.x;
    vec4 f104 = f103;
    f104.y = f102.y;
    vec4 f105 = f104;
    f105.z = f102.z;
    vec4 f106 = f105;
    f106.w = VARYING2.w;
    _entryPointOutput = f106;
}

//$$ShadowMapTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$PrefilteredEnvTexture=s15
//$$PrefilteredEnvIndoorTexture=s14
//$$PrefilteredEnvBlendTargetTexture=s2
//$$PrecomputedBRDFTexture=s11
//$$NoiseMapTexture=s9
//$$DiffuseMapTexture=s3
//$$NormalMapTexture=s4
//$$NormalDetailMapTexture=s8
//$$SpecularMapTexture=s5
