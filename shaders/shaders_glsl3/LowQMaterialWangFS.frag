#version 150

#extension GL_ARB_shading_language_include : require
#include <Globals.h>
#include <MaterialParams.h>
uniform vec4 CB0[53];
uniform vec4 CB2[4];
uniform sampler2D ShadowMapTexture;
uniform sampler3D LightMapTexture;
uniform sampler3D LightGridSkylightTexture;
uniform samplerCube PrefilteredEnvTexture;
uniform sampler2D WangTileMapTexture;
uniform sampler2D DiffuseMapTexture;

in vec2 VARYING0;
in vec4 VARYING2;
in vec4 VARYING3;
in vec4 VARYING4;
in vec4 VARYING5;
in vec4 VARYING6;
out vec4 _entryPointOutput;

void main()
{
    vec2 f0 = (VARYING0 * CB2[0].x) * 4.0;
    vec2 f1 = f0 * 0.25;
    vec4 f2 = vec4(dFdx(f1), dFdy(f1));
    vec4 f3 = textureGrad(DiffuseMapTexture, (texture(WangTileMapTexture, f0 * vec2(0.0078125)).xy * 0.99609375) + (fract(f0) * 0.25), f2.xy, f2.zw);
    vec3 f4 = mix(vec3(1.0), VARYING2.xyz, vec3(f3.w)) * f3.xyz;
    vec4 f5 = vec4(0.0);
    f5.x = f4.x;
    vec4 f6 = f5;
    f6.y = f4.y;
    vec4 f7 = f6;
    f7.z = f4.z;
    vec4 f8 = f7;
    f8.w = VARYING2.w;
    vec3 f9 = f8.xyz * f8.xyz;
    vec4 f10 = f8;
    f10.x = f9.x;
    vec4 f11 = f10;
    f11.y = f9.y;
    vec4 f12 = f11;
    f12.z = f9.z;
    vec3 f13 = VARYING6.xyz - (CB0[11].xyz * VARYING3.w);
    float f14 = clamp(dot(step(CB0[19].xyz, abs(VARYING3.xyz - CB0[18].xyz)), vec3(1.0)), 0.0, 1.0);
    vec3 f15 = VARYING3.yzx - (VARYING3.yzx * f14);
    vec4 f16 = vec4(clamp(f14, 0.0, 1.0));
    vec4 f17 = mix(texture(LightMapTexture, f15), vec4(0.0), f16);
    vec4 f18 = mix(texture(LightGridSkylightTexture, f15), vec4(1.0), f16);
    vec4 f19 = texture(ShadowMapTexture, f13.xy);
    float f20 = f13.z;
    float f21 = (1.0 - ((step(f19.x, f20) * clamp(CB0[24].z + (CB0[24].w * abs(f20 - 0.5)), 0.0, 1.0)) * f19.y)) * f18.y;
    vec3 f22 = (((VARYING5.xyz * f21) + min((f17.xyz * (f17.w * 120.0)) + (CB0[8].xyz + (CB0[9].xyz * f18.x)), vec3(CB0[16].w))) * f12.xyz) + ((CB0[10].xyz * mix(vec3(0.100000001490116119384765625), f12.xyz, vec3(VARYING6.w * CB0[26].w))) * (VARYING5.w * f21));
    vec4 f23 = vec4(0.0);
    f23.x = f22.x;
    vec4 f24 = f23;
    f24.y = f22.y;
    vec4 f25 = f24;
    f25.z = f22.z;
    vec4 f26 = f25;
    f26.w = VARYING2.w;
    float f27 = clamp(exp2((CB0[13].z * length(VARYING4.xyz)) + CB0[13].x) - CB0[13].w, 0.0, 1.0);
    vec3 f28 = textureLod(PrefilteredEnvTexture, vec4(-VARYING4.xyz, 0.0).xyz, max(CB0[13].y, f27) * 5.0).xyz;
    bvec3 f29 = bvec3(!(CB0[13].w == 0.0));
    vec3 f30 = mix(vec3(f29.x ? CB0[14].xyz.x : f28.x, f29.y ? CB0[14].xyz.y : f28.y, f29.z ? CB0[14].xyz.z : f28.z), f26.xyz, vec3(f27));
    vec4 f31 = f26;
    f31.x = f30.x;
    vec4 f32 = f31;
    f32.y = f30.y;
    vec4 f33 = f32;
    f33.z = f30.z;
    vec3 f34 = sqrt(clamp(f33.xyz * CB0[15].y, vec3(0.0), vec3(1.0)));
    vec4 f35 = f33;
    f35.x = f34.x;
    vec4 f36 = f35;
    f36.y = f34.y;
    vec4 f37 = f36;
    f37.z = f34.z;
    vec4 f38 = f37;
    f38.w = VARYING2.w;
    _entryPointOutput = f38;
}

//$$ShadowMapTexture=s1
//$$LightMapTexture=s6
//$$LightGridSkylightTexture=s7
//$$PrefilteredEnvTexture=s15
//$$WangTileMapTexture=s9
//$$DiffuseMapTexture=s3
