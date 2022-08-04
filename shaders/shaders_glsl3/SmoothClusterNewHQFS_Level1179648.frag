#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
uniform vec4 CB0[53];
uniform vec4 CB4[63];
uniform sampler2D ShadowMapTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube PrefilteredEnvTexture;
uniform samplerCube PrefilteredEnvIndoorTexture;
uniform samplerCube PrefilteredEnvBlendTargetTexture;
uniform sampler2D PrecomputedBRDFTexture;
uniform sampler2DArray SpecularMapTexture;
uniform sampler2DArray AlbedoMapTexture;

in vec4 VARYING0;
in vec4 VARYING1;
in vec4 VARYING2;
in vec4 VARYING3;
in vec3 VARYING4;
in vec4 VARYING5;
in vec3 VARYING6;
in vec3 VARYING8;
in vec4 VARYING9;
out vec4 _entryPointOutput;

void main()
{
    vec3 f0 = vec3(VARYING1.xy, VARYING2.x);
    vec4 f1 = texture(SpecularMapTexture, f0);
    vec3 f2 = vec3(VARYING1.zw, VARYING2.z);
    vec4 f3 = texture(SpecularMapTexture, f2);
    vec4 f4 = texture(SpecularMapTexture, VARYING3.xyz);
    vec4 f5 = ((f1 * VARYING0.x) + (f3 * VARYING0.y)) + (f4 * VARYING0.z);
    vec4 f6 = texture(AlbedoMapTexture, f0);
    vec4 f7 = texture(AlbedoMapTexture, f2);
    vec4 f8 = texture(AlbedoMapTexture, VARYING3.xyz);
    int f9 = int(VARYING9.x + 0.5);
    int f10 = int(VARYING9.y + 0.5);
    int f11 = int(VARYING9.z + 0.5);
    vec3 f12;
    if (!(CB4[f9 * 1 + 0].w == 0.0))
    {
        f12 = (mix(vec3(1.0), CB4[f9 * 1 + 0].xyz, vec3(f6.w)) * f6.xyz) * VARYING0.x;
    }
    else
    {
        vec2 f13 = f6.xz - vec2(0.5);
        float f14 = f13.x;
        float f15 = f13.y;
        float f16 = CB4[f9 * 1 + 0].x * f6.y;
        float f17 = (CB4[f9 * 1 + 0].y * f14) - (CB4[f9 * 1 + 0].z * f15);
        float f18 = (CB4[f9 * 1 + 0].z * f14) + (CB4[f9 * 1 + 0].y * f15);
        float f19 = f16 - f18;
        f12 = (vec3(f19, f16, f19) + (vec3(f17, f18, f17) * vec3(1.0, 1.0, -1.0))) * VARYING0.x;
    }
    vec3 f20;
    if (!(CB4[f10 * 1 + 0].w == 0.0))
    {
        f20 = f12 + ((mix(vec3(1.0), CB4[f10 * 1 + 0].xyz, vec3(f7.w)) * f7.xyz) * VARYING0.y);
    }
    else
    {
        vec2 f21 = f7.xz - vec2(0.5);
        float f22 = f21.x;
        float f23 = f21.y;
        float f24 = CB4[f10 * 1 + 0].x * f7.y;
        float f25 = (CB4[f10 * 1 + 0].y * f22) - (CB4[f10 * 1 + 0].z * f23);
        float f26 = (CB4[f10 * 1 + 0].z * f22) + (CB4[f10 * 1 + 0].y * f23);
        float f27 = f24 - f26;
        f20 = f12 + ((vec3(f27, f24, f27) + (vec3(f25, f26, f25) * vec3(1.0, 1.0, -1.0))) * VARYING0.y);
    }
    vec3 f28;
    if (!(CB4[f11 * 1 + 0].w == 0.0))
    {
        f28 = f20 + ((mix(vec3(1.0), CB4[f11 * 1 + 0].xyz, vec3(f8.w)) * f8.xyz) * VARYING0.z);
    }
    else
    {
        vec2 f29 = f8.xz - vec2(0.5);
        float f30 = f29.x;
        float f31 = f29.y;
        float f32 = CB4[f11 * 1 + 0].x * f8.y;
        float f33 = (CB4[f11 * 1 + 0].y * f30) - (CB4[f11 * 1 + 0].z * f31);
        float f34 = (CB4[f11 * 1 + 0].z * f30) + (CB4[f11 * 1 + 0].y * f31);
        float f35 = f32 - f34;
        f28 = f20 + ((vec3(f35, f32, f35) + (vec3(f33, f34, f33) * vec3(1.0, 1.0, -1.0))) * VARYING0.z);
    }
    vec3 f36 = f28 * f28;
    float f37 = clamp(1.0 - (VARYING5.w * CB0[23].y), 0.0, 1.0);
    vec3 f38 = normalize(VARYING6);
    vec3 f39 = VARYING5.xyz - (CB0[11].xyz * 0.001000000047497451305389404296875);
    float f40 = clamp(dot(step(CB0[19].xyz, abs(VARYING4 - CB0[18].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f41 = VARYING4.yzx - (VARYING4.yzx * f40);
    vec4 f42 = texture(LightMapTexture, f41);
    vec4 f43 = texture(LightGridSkylightTexture, f41);
    vec4 f44 = vec4(clamp(f40, 0.0, 1.0));
    vec4 f45 = mix(f42, vec4(0.0), f44);
    vec4 f46 = mix(f43, vec4(1.0), f44);
    float f47 = f46.x;
    vec4 f48 = texture(ShadowMapTexture, f39.xy);
    float f49 = f39.z;
    vec3 f50 = normalize(VARYING8);
    float f51 = 0.08900000154972076416015625 + (f5.y * 0.9110000133514404296875);
    float f52 = f5.x;
    vec3 f53 = mix(vec3(0.039999999105930328369140625), f36, vec3(f52));
    float f54 = CB0[26].w * f37;
    vec3 f55 = reflect(-f50, f38);
    vec3 f56 = -CB0[11].xyz;
    float f57 = (dot(f38, f56) * CB0[9].w) * ((1.0 - ((step(f48.x, f49) * clamp(CB0[24].z + (CB0[24].w * abs(f49 - 0.5)), 0.0, 1.0)) * f48.y)) * f46.y);
    vec3 f58 = normalize(f50 - CB0[11].xyz);
    float f59 = clamp(f57, 0.0, 1.0);
    float f60 = f51 * f51;
    float f61 = max(0.001000000047497451305389404296875, dot(f38, f58));
    float f62 = dot(f56, f58);
    float f63 = 1.0 - f62;
    float f64 = f63 * f63;
    float f65 = (f64 * f64) * f63;
    vec3 f66 = vec3(f65) + (f53 * (1.0 - f65));
    float f67 = f60 * f60;
    float f68 = (((f61 * f67) - f61) * f61) + 1.0;
    float f69 = 1.0 - f52;
    float f70 = f54 * f69;
    vec3 f71 = vec3(f69);
    float f72 = f51 * 5.0;
    vec3 f73 = vec4(f55, f72).xyz;
    vec3 f74 = textureLod(PrefilteredEnvIndoorTexture, f73, f72).xyz;
    vec3 f75;
    if (CB0[27].w == 0.0)
    {
        f75 = f74;
    }
    else
    {
        f75 = mix(f74, textureLod(PrefilteredEnvBlendTargetTexture, f73, f72).xyz, vec3(CB0[27].w));
    }
    vec4 f76 = texture(PrecomputedBRDFTexture, vec2(f51, max(9.9999997473787516355514526367188e-05, dot(f38, f50))));
    float f77 = f76.x;
    float f78 = f76.y;
    vec3 f79 = ((f53 * f77) + vec3(f78)) / vec3(f77 + f78);
    vec3 f80 = f38 * f38;
    bvec3 f81 = lessThan(f38, vec3(0.0));
    vec3 f82 = vec3(f81.x ? f80.x : vec3(0.0).x, f81.y ? f80.y : vec3(0.0).y, f81.z ? f80.z : vec3(0.0).z);
    vec3 f83 = f80 - f82;
    float f84 = f83.x;
    float f85 = f83.y;
    float f86 = f83.z;
    float f87 = f82.x;
    float f88 = f82.y;
    float f89 = f82.z;
    vec3 f90 = (((((((((f71 - (f66 * f70)) * CB0[10].xyz) * f59) + (CB0[12].xyz * (f69 * clamp(-f57, 0.0, 1.0)))) + ((f45.xyz * (f45.w * 120.0)) * 1.0)) + ((f71 - (f79 * f70)) * (((((((CB0[35].xyz * f84) + (CB0[37].xyz * f85)) + (CB0[39].xyz * f86)) + (CB0[36].xyz * f87)) + (CB0[38].xyz * f88)) + (CB0[40].xyz * f89)) + (((((((CB0[29].xyz * f84) + (CB0[31].xyz * f85)) + (CB0[33].xyz * f86)) + (CB0[30].xyz * f87)) + (CB0[32].xyz * f88)) + (CB0[34].xyz * f89)) * f47)))) + (CB0[27].xyz + ((CB0[28].xyz * (2.0 - CB0[9].w)) * f47))) + vec3((f5.z * 2.0) * f37)) * f36) + ((((((f66 * (((f67 + (f67 * f67)) / (((f68 * f68) * ((f62 * 3.0) + 0.5)) * ((f61 * 0.75) + 0.25))) * f59)) * CB0[10].xyz) * (CB0[9].w * CB0[9].w)) * f37) * VARYING0.w) + ((mix(f75, textureLod(PrefilteredEnvTexture, f73, f72).xyz * mix(CB0[26].xyz, CB0[25].xyz, vec3(clamp(f55.y * 1.58823525905609130859375, 0.0, 1.0))), vec3(f47)) * f79) * f54));
    vec4 f91 = vec4(0.0);
    f91.x = f90.x;
    vec4 f92 = f91;
    f92.y = f90.y;
    vec4 f93 = f92;
    f93.z = f90.z;
    vec4 f94 = f93;
    f94.w = 1.0;
    float f95 = clamp(exp2((CB0[13].z * VARYING5.w) + CB0[13].x) - CB0[13].w, 0.0, 1.0);
    vec3 f96 = textureLod(PrefilteredEnvTexture, vec4(-VARYING8, 0.0).xyz, max(CB0[13].y, f95) * 5.0).xyz;
    bvec3 f97 = bvec3(!(CB0[13].w == 0.0));
    vec3 f98 = mix(vec3(f97.x ? CB0[14].xyz.x : f96.x, f97.y ? CB0[14].xyz.y : f96.y, f97.z ? CB0[14].xyz.z : f96.z), f94.xyz, vec3(f95));
    vec4 f99 = f94;
    f99.x = f98.x;
    vec4 f100 = f99;
    f100.y = f98.y;
    vec4 f101 = f100;
    f101.z = f98.z;
    vec3 f102 = sqrt(clamp(f101.xyz * CB0[15].y, vec3(0.0), vec3(1.0)));
    vec4 f103 = f101;
    f103.x = f102.x;
    vec4 f104 = f103;
    f104.y = f102.y;
    vec4 f105 = f104;
    f105.z = f102.z;
    _entryPointOutput = f105;
}

//$$ShadowMapTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$PrefilteredEnvTexture=s15
//$$PrefilteredEnvIndoorTexture=s14
//$$PrefilteredEnvBlendTargetTexture=s2
//$$PrecomputedBRDFTexture=s11
//$$SpecularMapTexture=s3
//$$AlbedoMapTexture=s0
