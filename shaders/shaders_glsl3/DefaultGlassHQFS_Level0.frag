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
    float f0 = clamp(1.0 - (VARYING4.w * CB0[28].y), 0.0, 1.0);
    vec2 f1 = VARYING0 * CB2[0].x;
    vec4 f2 = texture(DiffuseMapTexture, f1);
    vec4 f3 = texture(NormalMapTexture, f1);
    vec2 f4 = f3.wy * 2.0;
    vec2 f5 = f4 - vec2(1.0);
    float f6 = sqrt(clamp(1.0 + dot(vec2(1.0) - f4, f5), 0.0, 1.0));
    vec3 f7 = vec3(f5, f6);
    vec2 f8 = f7.xy + (vec3((texture(NormalDetailMapTexture, f1 * CB2[0].w).wy * 2.0) - vec2(1.0), 0.0).xy * CB2[1].x);
    vec3 f9 = f7;
    f9.x = f8.x;
    vec3 f10 = f9;
    f10.y = f8.y;
    vec2 f11 = f10.xy * f0;
    float f12 = f11.x;
    vec3 f13 = (VARYING2.xyz * f2.xyz) * (1.0 + (f12 * 0.20000000298023223876953125));
    vec4 f14 = texture(SpecularMapTexture, f1 * CB2[1].w);
    vec4 f15 = texture(SpecularMapTexture, f1);
    float f16 = VARYING2.w * 2.0;
    float f17 = clamp((f16 - 1.0) + f2.w, 0.0, 1.0);
    float f18 = gl_FrontFacing ? 1.0 : (-1.0);
    vec3 f19 = VARYING6.xyz * f18;
    vec3 f20 = VARYING5.xyz * f18;
    vec3 f21 = normalize(((f19 * f12) + (cross(f20, f19) * f11.y)) + (f20 * (f6 * 10.0)));
    vec3 f22 = f13 * f13;
    float f23 = length(VARYING4.xyz);
    vec3 f24 = VARYING4.xyz / vec3(f23);
    float f25 = 0.08900000154972076416015625 + (mix(f14, f15, vec4(clamp((f0 * CB2[3].z) - (CB2[2].z * CB2[3].z), 0.0, 1.0))).y * 0.9110000133514404296875);
    float f26 = CB0[31].w * f0;
    float f27 = max(9.9999997473787516355514526367188e-05, dot(f21, f24));
    vec3 f28 = reflect(-f24, f21);
    float f29 = f25 * 5.0;
    vec3 f30 = vec4(f28, f29).xyz;
    vec3 f31 = textureLod(PrefilteredEnvTexture, f30, f29).xyz * mix(CB0[31].xyz, CB0[30].xyz, vec3(clamp(f28.y * 1.58823525905609130859375, 0.0, 1.0)));
    vec3 f32 = textureLod(PrefilteredEnvIndoorTexture, f30, f29).xyz;
    vec3 f33;
    if (CB0[32].w == 0.0)
    {
        f33 = f32;
    }
    else
    {
        f33 = mix(f32, textureLod(PrefilteredEnvBlendTargetTexture, f30, f29).xyz, vec3(CB0[32].w));
    }
    vec4 f34 = texture(PrecomputedBRDFTexture, vec2(f25, f27));
    vec3 f35 = VARYING7.xyz - (CB0[16].xyz * VARYING3.w);
    float f36 = clamp(dot(step(CB0[24].xyz, abs(VARYING3.xyz - CB0[23].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f37 = VARYING3.yzx - (VARYING3.yzx * f36);
    vec4 f38 = vec4(clamp(f36, 0.0, 1.0));
    vec4 f39 = mix(texture(LightMapTexture, f37), vec4(0.0), f38);
    vec4 f40 = mix(texture(LightGridSkylightTexture, f37), vec4(1.0), f38);
    vec3 f41 = f39.xyz * (f39.w * 120.0);
    float f42 = f40.x;
    vec4 f43 = texture(ShadowMapTexture, f35.xy);
    float f44 = f35.z;
    vec3 f45 = vec3(f42);
    vec3 f46 = mix(f41, f31, f45) * mix(vec3(1.0), f22, vec3(0.5));
    float f47 = CB0[14].w * CB0[14].w;
    vec3 f48 = -CB0[16].xyz;
    float f49 = (dot(f21, f48) * CB0[14].w) * ((1.0 - ((step(f43.x, f44) * clamp(CB0[29].z + (CB0[29].w * abs(f44 - 0.5)), 0.0, 1.0)) * f43.y)) * f40.y);
    vec3 f50 = normalize(f24 - CB0[16].xyz);
    float f51 = clamp(f49, 0.0, 1.0);
    float f52 = f25 * f25;
    float f53 = max(0.001000000047497451305389404296875, dot(f21, f50));
    float f54 = dot(f48, f50);
    float f55 = 1.0 - f54;
    float f56 = f55 * f55;
    float f57 = (f56 * f56) * f55;
    vec3 f58 = vec3(f57) + (vec3(0.039999999105930328369140625) * (1.0 - f57));
    float f59 = f52 * f52;
    float f60 = (((f53 * f59) - f53) * f53) + 1.0;
    float f61 = f34.x;
    float f62 = f34.y;
    vec3 f63 = ((vec3(0.039999999105930328369140625) * f61) + vec3(f62)) / vec3(f61 + f62);
    vec3 f64 = f21 * f21;
    bvec3 f65 = lessThan(f21, vec3(0.0));
    vec3 f66 = vec3(f65.x ? f64.x : vec3(0.0).x, f65.y ? f64.y : vec3(0.0).y, f65.z ? f64.z : vec3(0.0).z);
    vec3 f67 = f64 - f66;
    float f68 = f67.x;
    float f69 = f67.y;
    float f70 = f67.z;
    float f71 = f66.x;
    float f72 = f66.y;
    float f73 = f66.z;
    float f74 = 1.0 - f27;
    vec4 f75 = mix(vec4(mix(((((f41 * f17) + ((((vec3(1.0) - (f58 * f26)) * CB0[15].xyz) * f51) + (CB0[17].xyz * clamp(-f49, 0.0, 1.0)))) + (((vec3(1.0) - (f63 * f26)) * (((((((CB0[40].xyz * f68) + (CB0[42].xyz * f69)) + (CB0[44].xyz * f70)) + (CB0[41].xyz * f71)) + (CB0[43].xyz * f72)) + (CB0[45].xyz * f73)) + (((((((CB0[34].xyz * f68) + (CB0[36].xyz * f69)) + (CB0[38].xyz * f70)) + (CB0[35].xyz * f71)) + (CB0[37].xyz * f72)) + (CB0[39].xyz * f73)) * f42))) * f17)) + (CB0[32].xyz + ((CB0[33].xyz * (2.0 - CB0[14].w)) * f42))) * (f22 * f17), f46, vec3(VARYING7.w)) * f17, f17), vec4(f46, 1.0), vec4(((f74 * f74) * 0.800000011920928955078125) * clamp(f16, 0.0, 1.0))) + vec4((((f58 * (((f59 + (f59 * f59)) / (((f60 * f60) * ((f54 * 3.0) + 0.5)) * ((f53 * 0.75) + 0.25))) * f51)) * CB0[15].xyz) * f47) + (((mix(f33, f31, f45) * f63) * f26) * (f47 * f17)), 0.0);
    float f76 = clamp(exp2((CB0[18].z * f23) + CB0[18].x) - CB0[18].w, 0.0, 1.0);
    vec3 f77 = textureLod(PrefilteredEnvTexture, vec4(-VARYING4.xyz, 0.0).xyz, max(CB0[18].y, f76) * 5.0).xyz;
    bvec3 f78 = bvec3(!(CB0[18].w == 0.0));
    vec3 f79 = mix(vec3(f78.x ? CB0[19].xyz.x : f77.x, f78.y ? CB0[19].xyz.y : f77.y, f78.z ? CB0[19].xyz.z : f77.z), f75.xyz, vec3(f76));
    vec4 f80 = f75;
    f80.x = f79.x;
    vec4 f81 = f80;
    f81.y = f79.y;
    vec4 f82 = f81;
    f82.z = f79.z;
    vec4 f83 = f82;
    f83.w = 1.0 - ((1.0 - f75.w) * f76);
    vec3 f84 = sqrt(clamp(f83.xyz * CB0[20].y, vec3(0.0), vec3(1.0)));
    vec4 f85 = f83;
    f85.x = f84.x;
    vec4 f86 = f85;
    f86.y = f84.y;
    vec4 f87 = f86;
    f87.z = f84.z;
    _entryPointOutput = f87;
}

//$$ShadowMapTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$PrefilteredEnvTexture=s15
//$$PrefilteredEnvIndoorTexture=s14
//$$PrefilteredEnvBlendTargetTexture=s2
//$$PrecomputedBRDFTexture=s11
//$$DiffuseMapTexture=s3
//$$NormalMapTexture=s4
//$$NormalDetailMapTexture=s8
//$$SpecularMapTexture=s5
