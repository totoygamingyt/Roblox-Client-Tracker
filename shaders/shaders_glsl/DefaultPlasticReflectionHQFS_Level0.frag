#version 110

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <MaterialParams.h>
uniform vec4 CB0[53];
uniform vec4 CB2[4];
uniform sampler2D ShadowMapTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube EnvironmentMapTexture;
uniform sampler2D DiffuseMapTexture;
uniform sampler2D NormalMapTexture;
uniform sampler2D NormalDetailMapTexture;

varying vec2 VARYING0;
varying vec2 VARYING1;
varying vec4 VARYING2;
varying vec4 VARYING3;
varying vec4 VARYING4;
varying vec4 VARYING5;
varying vec4 VARYING6;
varying vec4 VARYING7;
varying float VARYING8;

void main()
{
    float f0 = length(VARYING4.xyz);
    vec3 f1 = VARYING4.xyz / vec3(f0);
    vec2 f2 = VARYING1;
    f2.y = (fract(VARYING1.y) + VARYING8) * 0.25;
    float f3 = clamp(1.0 - (VARYING4.w * CB0[23].y), 0.0, 1.0);
    vec2 f4 = texture2D(NormalMapTexture, f2).wy * 2.0;
    vec2 f5 = f4 - vec2(1.0);
    float f6 = sqrt(clamp(1.0 + dot(vec2(1.0) - f4, f5), 0.0, 1.0));
    vec3 f7 = vec3(f5, f6);
    vec2 f8 = f7.xy + (vec3((texture2D(NormalDetailMapTexture, VARYING0 * CB2[0].x).wy * 2.0) - vec2(1.0), 0.0).xy * (clamp(VARYING2.w - 0.5, 0.0, 1.0) * clamp(1.0 - (2.0 * VARYING7.w), 0.0, 1.0)));
    vec3 f9 = f7;
    f9.x = f8.x;
    vec3 f10 = f9;
    f10.y = f8.y;
    vec2 f11 = f10.xy * (f3 * CB2[3].w);
    vec4 f12 = vec4(VARYING2.xyz * (texture2D(DiffuseMapTexture, f2).x * 2.0), VARYING2.w);
    float f13 = gl_FrontFacing ? 1.0 : (-1.0);
    vec3 f14 = VARYING6.xyz * f13;
    vec3 f15 = VARYING5.xyz * f13;
    vec3 f16 = normalize(((f14 * f11.x) + (cross(f15, f14) * f11.y)) + (f15 * f6));
    vec3 f17 = f12.xyz;
    vec3 f18 = f17 * f17;
    vec4 f19 = f12;
    f19.x = f18.x;
    vec4 f20 = f19;
    f20.y = f18.y;
    vec4 f21 = f20;
    f21.z = f18.z;
    vec3 f22 = VARYING7.xyz - (CB0[11].xyz * VARYING3.w);
    float f23 = clamp(dot(step(CB0[19].xyz, abs(VARYING3.xyz - CB0[18].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f24 = VARYING3.yzx - (VARYING3.yzx * f23);
    vec4 f25 = vec4(clamp(f23, 0.0, 1.0));
    vec4 f26 = mix(texture3D(LightMapTexture, f24), vec4(0.0), f25);
    vec4 f27 = mix(texture3D(LightGridSkylightTexture, f24), vec4(1.0), f25);
    vec4 f28 = texture2D(ShadowMapTexture, f22.xy);
    float f29 = f22.z;
    float f30 = 0.08900000154972076416015625 + (CB2[0].y * 0.9110000133514404296875);
    vec3 f31 = textureCube(EnvironmentMapTexture, reflect(-f1, f16)).xyz;
    vec3 f32 = -CB0[11].xyz;
    float f33 = (dot(f16, f32) * CB0[9].w) * ((1.0 - ((step(f28.x, f29) * clamp(CB0[24].z + (CB0[24].w * abs(f29 - 0.5)), 0.0, 1.0)) * f28.y)) * f27.y);
    vec3 f34 = normalize(f1 - CB0[11].xyz);
    float f35 = clamp(f33, 0.0, 1.0);
    float f36 = f30 * f30;
    float f37 = max(0.001000000047497451305389404296875, dot(f16, f34));
    float f38 = dot(f32, f34);
    float f39 = 1.0 - f38;
    float f40 = f39 * f39;
    float f41 = (f40 * f40) * f39;
    vec3 f42 = vec3(f41) + (vec3(0.039999999105930328369140625) * (1.0 - f41));
    float f43 = f36 * f36;
    float f44 = (((f37 * f43) - f37) * f37) + 1.0;
    vec3 f45 = ((((((vec3(1.0) - (f42 * (CB0[26].w * f3))) * CB0[10].xyz) * f35) + (CB0[12].xyz * clamp(-f33, 0.0, 1.0))) + min((f26.xyz * (f26.w * 120.0)) + (CB0[8].xyz + (CB0[9].xyz * f27.x)), vec3(CB0[16].w))) * mix(f21.xyz, (f31 * f31) * CB0[15].x, vec3(VARYING7.w))) + (((f42 * (((f43 + (f43 * f43)) / (((f44 * f44) * ((f38 * 3.0) + 0.5)) * ((f37 * 0.75) + 0.25))) * f35)) * CB0[10].xyz) * (CB0[9].w * CB0[9].w));
    vec4 f46 = vec4(0.0);
    f46.x = f45.x;
    vec4 f47 = f46;
    f47.y = f45.y;
    vec4 f48 = f47;
    f48.z = f45.z;
    vec4 f49 = f48;
    f49.w = VARYING2.w;
    vec3 f50 = mix(CB0[14].xyz, f49.xyz, vec3(clamp(exp2((CB0[13].z * f0) + CB0[13].x) - CB0[13].w, 0.0, 1.0)));
    vec4 f51 = f49;
    f51.x = f50.x;
    vec4 f52 = f51;
    f52.y = f50.y;
    vec4 f53 = f52;
    f53.z = f50.z;
    vec3 f54 = sqrt(clamp(f53.xyz * CB0[15].y, vec3(0.0), vec3(1.0))) + vec3((-0.00048828125) + (0.0009765625 * fract(52.98291778564453125 * fract(dot(gl_FragCoord.xy, vec2(0.067110560834407806396484375, 0.005837149918079376220703125))))));
    vec4 f55 = f53;
    f55.x = f54.x;
    vec4 f56 = f55;
    f56.y = f54.y;
    vec4 f57 = f56;
    f57.z = f54.z;
    vec4 f58 = f57;
    f58.w = VARYING2.w;
    gl_FragData[0] = f58;
}

//$$ShadowMapTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$EnvironmentMapTexture=s2
//$$DiffuseMapTexture=s3
//$$NormalMapTexture=s4
//$$NormalDetailMapTexture=s8
