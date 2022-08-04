#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
uniform vec4 CB0[53];
uniform vec4 CB4[63];
uniform vec4 CB5[63];
uniform sampler2D ShadowMapTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube PrefilteredEnvTexture;
uniform samplerCube PrefilteredEnvIndoorTexture;
uniform samplerCube PrefilteredEnvBlendTargetTexture;
uniform sampler2D PrecomputedBRDFTexture;
uniform sampler2DArray SpecularMapTexture;
uniform sampler2DArray AlbedoMapTexture;
uniform sampler2DArray NormalMapTexture;

in vec4 VARYING0;
in vec4 VARYING1;
in vec4 VARYING2;
in vec4 VARYING3;
in vec3 VARYING4;
in vec4 VARYING5;
in vec3 VARYING6;
in vec3 VARYING7;
in vec4 VARYING8;
in vec3 VARYING9;
in vec4 VARYING10;
out vec4 _entryPointOutput;

void main()
{
    vec3 f0 = vec3(VARYING1.xy, VARYING2.x);
    vec4 f1 = texture(SpecularMapTexture, f0);
    vec3 f2 = vec3(VARYING1.zw, VARYING2.z);
    vec4 f3 = texture(SpecularMapTexture, f2);
    vec4 f4 = texture(SpecularMapTexture, VARYING3.xyz);
    vec3 f5;
    if (VARYING8.w < 1.0)
    {
        ivec3 f6 = ivec3(VARYING8.xyz + vec3(0.5));
        int f7 = f6.x;
        int f8 = f6.y;
        int f9 = f6.z;
        float f10 = dot(VARYING0.xyz, vec3(CB5[f7 * 1 + 0].z, CB5[f8 * 1 + 0].z, CB5[f9 * 1 + 0].z));
        float f11 = f1.w;
        float f12 = f3.w;
        float f13 = f4.w;
        vec3 f14 = vec3(f11, f12, f13);
        f14.x = clamp((f11 * CB5[f7 * 1 + 0].x) + CB5[f7 * 1 + 0].y, 0.0, 1.0);
        vec3 f15 = f14;
        f15.y = clamp((f12 * CB5[f8 * 1 + 0].x) + CB5[f8 * 1 + 0].y, 0.0, 1.0);
        vec3 f16 = f15;
        f16.z = clamp((f13 * CB5[f9 * 1 + 0].x) + CB5[f9 * 1 + 0].y, 0.0, 1.0);
        vec3 f17 = VARYING0.xyz * f16;
        float f18 = 1.0 / f10;
        float f19 = 0.5 * f10;
        float f20 = f17.x;
        float f21 = f17.y;
        float f22 = f17.z;
        float f23 = clamp(((f20 - max(f21, f22)) + f19) * f18, 0.0, 1.0);
        float f24 = clamp(((f21 - max(f20, f22)) + f19) * f18, 0.0, 1.0);
        float f25 = clamp(((f22 - max(f20, f21)) + f19) * f18, 0.0, 1.0);
        vec2 f26 = dFdx(VARYING1.xy);
        vec2 f27 = dFdy(VARYING1.xy);
        f5 = mix(vec3(f23, f24, f25) / vec3((f23 + f24) + f25), VARYING0.xyz, vec3(clamp((sqrt(max(dot(f26, f26), dot(f27, f27))) * 7.0) + clamp(VARYING8.w, 0.0, 1.0), 0.0, 1.0)));
    }
    else
    {
        f5 = VARYING0.xyz;
    }
    vec4 f28 = ((f1 * f5.x) + (f3 * f5.y)) + (f4 * f5.z);
    vec4 f29 = texture(AlbedoMapTexture, f0);
    vec4 f30 = texture(AlbedoMapTexture, f2);
    vec4 f31 = texture(AlbedoMapTexture, VARYING3.xyz);
    int f32 = int(VARYING10.x + 0.5);
    int f33 = int(VARYING10.y + 0.5);
    int f34 = int(VARYING10.z + 0.5);
    vec2 f35 = f29.xz - vec2(0.5);
    float f36 = f35.x;
    vec4 f37 = f29.yxzw;
    f37.y = f36;
    float f38 = f35.y;
    vec4 f39 = f37;
    f39.z = f38;
    vec2 f40 = f30.xz - vec2(0.5);
    float f41 = f40.x;
    vec4 f42 = f30.yxzw;
    f42.y = f41;
    float f43 = f40.y;
    vec4 f44 = f42;
    f44.z = f43;
    vec2 f45 = f31.xz - vec2(0.5);
    float f46 = f45.x;
    vec4 f47 = f31.yxzw;
    f47.y = f46;
    float f48 = f45.y;
    vec4 f49 = f47;
    f49.z = f48;
    vec3 f50;
    vec4 f51;
    if (!(CB4[f32 * 1 + 0].w == 0.0))
    {
        f51 = f39;
        f50 = mix(vec3(1.0), CB4[f32 * 1 + 0].xyz, vec3(f29.w)) * f5.x;
    }
    else
    {
        vec4 f52 = f39;
        f52.x = CB4[f32 * 1 + 0].x * f29.y;
        vec4 f53 = f52;
        f53.y = (CB4[f32 * 1 + 0].y * f36) - (CB4[f32 * 1 + 0].z * f38);
        vec4 f54 = f53;
        f54.z = (CB4[f32 * 1 + 0].z * f36) + (CB4[f32 * 1 + 0].y * f38);
        f51 = f54;
        f50 = vec3(f5.x);
    }
    vec3 f55;
    vec4 f56;
    if (!(CB4[f33 * 1 + 0].w == 0.0))
    {
        f56 = f44;
        f55 = f50 + (mix(vec3(1.0), CB4[f33 * 1 + 0].xyz, vec3(f30.w)) * f5.y);
    }
    else
    {
        vec4 f57 = f44;
        f57.x = CB4[f33 * 1 + 0].x * f30.y;
        vec4 f58 = f57;
        f58.y = (CB4[f33 * 1 + 0].y * f41) - (CB4[f33 * 1 + 0].z * f43);
        vec4 f59 = f58;
        f59.z = (CB4[f33 * 1 + 0].z * f41) + (CB4[f33 * 1 + 0].y * f43);
        f56 = f59;
        f55 = f50 + vec3(f5.y);
    }
    vec3 f60;
    vec4 f61;
    if (!(CB4[f34 * 1 + 0].w == 0.0))
    {
        f61 = f49;
        f60 = f55 + (mix(vec3(1.0), CB4[f34 * 1 + 0].xyz, vec3(f31.w)) * f5.z);
    }
    else
    {
        vec4 f62 = f49;
        f62.x = CB4[f34 * 1 + 0].x * f31.y;
        vec4 f63 = f62;
        f63.y = (CB4[f34 * 1 + 0].y * f46) - (CB4[f34 * 1 + 0].z * f48);
        vec4 f64 = f63;
        f64.z = (CB4[f34 * 1 + 0].z * f46) + (CB4[f34 * 1 + 0].y * f48);
        f61 = f64;
        f60 = f55 + vec3(f5.z);
    }
    vec4 f65 = ((f51 * f5.x) + (f56 * f5.y)) + (f61 * f5.z);
    float f66 = f65.x;
    float f67 = f66 - f65.z;
    vec3 f68 = vec4(vec3(f67, f66, f67) + (vec3(f65.yzy) * vec3(1.0, 1.0, -1.0)), 0.0).xyz * f60;
    vec4 f69 = vec4(0.0);
    f69.x = f68.x;
    vec4 f70 = f69;
    f70.y = f68.y;
    vec4 f71 = f70;
    f71.z = f68.z;
    vec3 f72 = f71.xyz * f71.xyz;
    float f73 = clamp(1.0 - (VARYING5.w * CB0[23].y), 0.0, 1.0);
    vec4 f74 = texture(NormalMapTexture, f0);
    vec4 f75 = texture(NormalMapTexture, f2);
    vec4 f76 = texture(NormalMapTexture, VARYING3.xyz);
    vec2 f77 = (((f74 * f5.x) + (f75 * f5.y)) + (f76 * f5.z)).wy * 2.0;
    vec2 f78 = f77 - vec2(1.0);
    vec3 f79 = normalize(((vec3(f78, sqrt(clamp(1.0 + dot(vec2(1.0) - f77, f78), 0.0, 1.0))) - vec3(0.0, 0.0, 1.0)) * inversesqrt(dot(f5, f5))) + vec3(0.0, 0.0, 1.0));
    vec3 f80 = vec3(dot(VARYING7, f5));
    vec3 f81 = vec4(normalize(((mix(vec3(VARYING6.z, 0.0, -VARYING6.x), vec3(-VARYING6.y, VARYING6.x, 0.0), f80) * f79.x) + (mix(vec3(0.0, 1.0, 0.0), vec3(0.0, -VARYING6.z, VARYING6.y), f80) * f79.y)) + (VARYING6 * f79.z)), 0.0).xyz;
    vec3 f82 = VARYING5.xyz - (CB0[11].xyz * 0.001000000047497451305389404296875);
    float f83 = clamp(dot(step(CB0[19].xyz, abs(VARYING4 - CB0[18].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f84 = VARYING4.yzx - (VARYING4.yzx * f83);
    vec4 f85 = texture(LightMapTexture, f84);
    vec4 f86 = texture(LightGridSkylightTexture, f84);
    vec4 f87 = vec4(clamp(f83, 0.0, 1.0));
    vec4 f88 = mix(f85, vec4(0.0), f87);
    vec4 f89 = mix(f86, vec4(1.0), f87);
    float f90 = f89.x;
    vec4 f91 = texture(ShadowMapTexture, f82.xy);
    float f92 = f82.z;
    vec3 f93 = normalize(VARYING9);
    float f94 = 0.08900000154972076416015625 + (f28.y * 0.9110000133514404296875);
    float f95 = f28.x;
    vec3 f96 = mix(vec3(0.039999999105930328369140625), f72, vec3(f95));
    float f97 = CB0[26].w * f73;
    vec3 f98 = reflect(-f93, f81);
    vec3 f99 = -CB0[11].xyz;
    float f100 = (dot(f81, f99) * CB0[9].w) * ((1.0 - ((step(f91.x, f92) * clamp(CB0[24].z + (CB0[24].w * abs(f92 - 0.5)), 0.0, 1.0)) * f91.y)) * f89.y);
    vec3 f101 = normalize(f93 - CB0[11].xyz);
    float f102 = clamp(f100, 0.0, 1.0);
    float f103 = f94 * f94;
    float f104 = max(0.001000000047497451305389404296875, dot(f81, f101));
    float f105 = dot(f99, f101);
    float f106 = 1.0 - f105;
    float f107 = f106 * f106;
    float f108 = (f107 * f107) * f106;
    vec3 f109 = vec3(f108) + (f96 * (1.0 - f108));
    float f110 = f103 * f103;
    float f111 = (((f104 * f110) - f104) * f104) + 1.0;
    float f112 = 1.0 - f95;
    float f113 = f97 * f112;
    vec3 f114 = vec3(f112);
    float f115 = f94 * 5.0;
    vec3 f116 = vec4(f98, f115).xyz;
    vec3 f117 = textureLod(PrefilteredEnvIndoorTexture, f116, f115).xyz;
    vec3 f118;
    if (CB0[27].w == 0.0)
    {
        f118 = f117;
    }
    else
    {
        f118 = mix(f117, textureLod(PrefilteredEnvBlendTargetTexture, f116, f115).xyz, vec3(CB0[27].w));
    }
    vec4 f119 = texture(PrecomputedBRDFTexture, vec2(f94, max(9.9999997473787516355514526367188e-05, dot(f81, f93))));
    float f120 = f119.x;
    float f121 = f119.y;
    vec3 f122 = ((f96 * f120) + vec3(f121)) / vec3(f120 + f121);
    vec3 f123 = f81 * f81;
    bvec3 f124 = lessThan(f81, vec3(0.0));
    vec3 f125 = vec3(f124.x ? f123.x : vec3(0.0).x, f124.y ? f123.y : vec3(0.0).y, f124.z ? f123.z : vec3(0.0).z);
    vec3 f126 = f123 - f125;
    float f127 = f126.x;
    float f128 = f126.y;
    float f129 = f126.z;
    float f130 = f125.x;
    float f131 = f125.y;
    float f132 = f125.z;
    vec3 f133 = (((((((((f114 - (f109 * f113)) * CB0[10].xyz) * f102) + (CB0[12].xyz * (f112 * clamp(-f100, 0.0, 1.0)))) + ((f88.xyz * (f88.w * 120.0)) * 1.0)) + ((f114 - (f122 * f113)) * (((((((CB0[35].xyz * f127) + (CB0[37].xyz * f128)) + (CB0[39].xyz * f129)) + (CB0[36].xyz * f130)) + (CB0[38].xyz * f131)) + (CB0[40].xyz * f132)) + (((((((CB0[29].xyz * f127) + (CB0[31].xyz * f128)) + (CB0[33].xyz * f129)) + (CB0[30].xyz * f130)) + (CB0[32].xyz * f131)) + (CB0[34].xyz * f132)) * f90)))) + (CB0[27].xyz + ((CB0[28].xyz * (2.0 - CB0[9].w)) * f90))) + vec3((f28.z * 2.0) * f73)) * f72) + ((((((f109 * (((f110 + (f110 * f110)) / (((f111 * f111) * ((f105 * 3.0) + 0.5)) * ((f104 * 0.75) + 0.25))) * f102)) * CB0[10].xyz) * (CB0[9].w * CB0[9].w)) * f73) * VARYING0.w) + ((mix(f118, textureLod(PrefilteredEnvTexture, f116, f115).xyz * mix(CB0[26].xyz, CB0[25].xyz, vec3(clamp(f98.y * 1.58823525905609130859375, 0.0, 1.0))), vec3(f90)) * f122) * f97));
    vec4 f134 = vec4(0.0);
    f134.x = f133.x;
    vec4 f135 = f134;
    f135.y = f133.y;
    vec4 f136 = f135;
    f136.z = f133.z;
    vec4 f137 = f136;
    f137.w = 1.0;
    float f138 = clamp(exp2((CB0[13].z * VARYING5.w) + CB0[13].x) - CB0[13].w, 0.0, 1.0);
    vec3 f139 = textureLod(PrefilteredEnvTexture, vec4(-VARYING9, 0.0).xyz, max(CB0[13].y, f138) * 5.0).xyz;
    bvec3 f140 = bvec3(!(CB0[13].w == 0.0));
    vec3 f141 = mix(vec3(f140.x ? CB0[14].xyz.x : f139.x, f140.y ? CB0[14].xyz.y : f139.y, f140.z ? CB0[14].xyz.z : f139.z), f137.xyz, vec3(f138));
    vec4 f142 = f137;
    f142.x = f141.x;
    vec4 f143 = f142;
    f143.y = f141.y;
    vec4 f144 = f143;
    f144.z = f141.z;
    vec3 f145 = sqrt(clamp(f144.xyz * CB0[15].y, vec3(0.0), vec3(1.0)));
    vec4 f146 = f144;
    f146.x = f145.x;
    vec4 f147 = f146;
    f147.y = f145.y;
    vec4 f148 = f147;
    f148.z = f145.z;
    _entryPointOutput = f148;
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
//$$NormalMapTexture=s4
