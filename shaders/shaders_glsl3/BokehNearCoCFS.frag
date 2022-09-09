#version 150

#extension GL_ARB_shading_language_include : require
#include <Params.h>
uniform vec4 CB1[10];
uniform sampler2D iChannel0Texture;
uniform sampler2D iChannel1Texture;

in vec2 VARYING0;
out vec4 _entryPointOutput;

void main()
{
    vec4 f0 = texture(iChannel0Texture, VARYING0);
    vec4 f1 = texture(iChannel1Texture, VARYING0);
    float f2 = f1.x;
    float f3 = f2 * f2;
    float f4 = f3 * CB1[1].y;
    vec2 f5 = vec2(CB1[0].y * CB1[0].z, 1.0) * 0.01400000043213367462158203125;
    vec2 f6 = ((vec2(0.22490672767162322998046875, 0.16340430080890655517578125) * f4) * f5) + VARYING0;
    vec4 f7 = texture(iChannel0Texture, f6);
    float f8 = f7.w;
    float f9 = f6.x;
    float f10 = f6.y;
    float f11;
    vec4 f12;
    if ((((f9 >= 0.0) && (f9 <= 1.0)) && (f10 >= 0.0)) && (f10 <= 1.0))
    {
        f12 = f0 + (f7 * f8);
        f11 = f3 + f8;
    }
    else
    {
        f12 = f0;
        f11 = f3;
    }
    vec2 f13 = ((vec2(-0.085906721651554107666015625, 0.2643937170505523681640625) * f4) * f5) + VARYING0;
    vec4 f14 = texture(iChannel0Texture, f13);
    float f15 = f14.w;
    float f16 = f13.x;
    float f17 = f13.y;
    float f18;
    vec4 f19;
    if ((((f16 >= 0.0) && (f16 <= 1.0)) && (f17 >= 0.0)) && (f17 <= 1.0))
    {
        f19 = f12 + (f14 * f15);
        f18 = f11 + f15;
    }
    else
    {
        f19 = f12;
        f18 = f11;
    }
    vec2 f20 = ((vec2(-0.27799999713897705078125, 3.4044057403885696227487100973264e-17) * f4) * f5) + VARYING0;
    vec4 f21 = texture(iChannel0Texture, f20);
    float f22 = f21.w;
    float f23 = f20.x;
    float f24 = f20.y;
    float f25;
    vec4 f26;
    if ((((f23 >= 0.0) && (f23 <= 1.0)) && (f24 >= 0.0)) && (f24 <= 1.0))
    {
        f26 = f19 + (f21 * f22);
        f25 = f18 + f22;
    }
    else
    {
        f26 = f19;
        f25 = f18;
    }
    vec2 f27 = ((vec2(-0.085906721651554107666015625, -0.2643937170505523681640625) * f4) * f5) + VARYING0;
    vec4 f28 = texture(iChannel0Texture, f27);
    float f29 = f28.w;
    float f30 = f27.x;
    float f31 = f27.y;
    float f32;
    vec4 f33;
    if ((((f30 >= 0.0) && (f30 <= 1.0)) && (f31 >= 0.0)) && (f31 <= 1.0))
    {
        f33 = f26 + (f28 * f29);
        f32 = f25 + f29;
    }
    else
    {
        f33 = f26;
        f32 = f25;
    }
    vec2 f34 = ((vec2(0.22490672767162322998046875, -0.16340430080890655517578125) * f4) * f5) + VARYING0;
    vec4 f35 = texture(iChannel0Texture, f34);
    float f36 = f35.w;
    float f37 = f34.x;
    float f38 = f34.y;
    float f39;
    vec4 f40;
    if ((((f37 >= 0.0) && (f37 <= 1.0)) && (f38 >= 0.0)) && (f38 <= 1.0))
    {
        f40 = f33 + (f35 * f36);
        f39 = f32 + f36;
    }
    else
    {
        f40 = f33;
        f39 = f32;
    }
    vec2 f41 = ((vec2(0.540000021457672119140625, 0.0) * f4) * f5) + VARYING0;
    vec4 f42 = texture(iChannel0Texture, f41);
    float f43 = f42.w;
    float f44 = f41.x;
    float f45 = f41.y;
    float f46;
    vec4 f47;
    if ((((f44 >= 0.0) && (f44 <= 1.0)) && (f45 >= 0.0)) && (f45 <= 1.0))
    {
        f47 = f40 + (f42 * f43);
        f46 = f39 + f43;
    }
    else
    {
        f47 = f40;
        f46 = f39;
    }
    vec2 f48 = ((vec2(0.436869204044342041015625, 0.3174040615558624267578125) * f4) * f5) + VARYING0;
    vec4 f49 = texture(iChannel0Texture, f48);
    float f50 = f49.w;
    float f51 = f48.x;
    float f52 = f48.y;
    float f53;
    vec4 f54;
    if ((((f51 >= 0.0) && (f51 <= 1.0)) && (f52 >= 0.0)) && (f52 <= 1.0))
    {
        f54 = f47 + (f49 * f50);
        f53 = f46 + f50;
    }
    else
    {
        f54 = f47;
        f53 = f46;
    }
    vec2 f55 = ((vec2(0.16686917841434478759765625, 0.5135705471038818359375) * f4) * f5) + VARYING0;
    vec4 f56 = texture(iChannel0Texture, f55);
    float f57 = f56.w;
    float f58 = f55.x;
    float f59 = f55.y;
    float f60;
    vec4 f61;
    if ((((f58 >= 0.0) && (f58 <= 1.0)) && (f59 >= 0.0)) && (f59 <= 1.0))
    {
        f61 = f54 + (f56 * f57);
        f60 = f53 + f57;
    }
    else
    {
        f61 = f54;
        f60 = f53;
    }
    vec2 f62 = ((vec2(-0.16686917841434478759765625, 0.5135705471038818359375) * f4) * f5) + VARYING0;
    vec4 f63 = texture(iChannel0Texture, f62);
    float f64 = f63.w;
    float f65 = f62.x;
    float f66 = f62.y;
    float f67;
    vec4 f68;
    if ((((f65 >= 0.0) && (f65 <= 1.0)) && (f66 >= 0.0)) && (f66 <= 1.0))
    {
        f68 = f61 + (f63 * f64);
        f67 = f60 + f64;
    }
    else
    {
        f68 = f61;
        f67 = f60;
    }
    vec2 f69 = ((vec2(-0.436869204044342041015625, 0.3174040615558624267578125) * f4) * f5) + VARYING0;
    vec4 f70 = texture(iChannel0Texture, f69);
    float f71 = f70.w;
    float f72 = f69.x;
    float f73 = f69.y;
    float f74;
    vec4 f75;
    if ((((f72 >= 0.0) && (f72 <= 1.0)) && (f73 >= 0.0)) && (f73 <= 1.0))
    {
        f75 = f68 + (f70 * f71);
        f74 = f67 + f71;
    }
    else
    {
        f75 = f68;
        f74 = f67;
    }
    vec2 f76 = ((vec2(-0.540000021457672119140625, 6.6128748929759884316731399778178e-17) * f4) * f5) + VARYING0;
    vec4 f77 = texture(iChannel0Texture, f76);
    float f78 = f77.w;
    float f79 = f76.x;
    float f80 = f76.y;
    float f81;
    vec4 f82;
    if ((((f79 >= 0.0) && (f79 <= 1.0)) && (f80 >= 0.0)) && (f80 <= 1.0))
    {
        f82 = f75 + (f77 * f78);
        f81 = f74 + f78;
    }
    else
    {
        f82 = f75;
        f81 = f74;
    }
    vec2 f83 = ((vec2(-0.436869204044342041015625, -0.3174040615558624267578125) * f4) * f5) + VARYING0;
    vec4 f84 = texture(iChannel0Texture, f83);
    float f85 = f84.w;
    float f86 = f83.x;
    float f87 = f83.y;
    float f88;
    vec4 f89;
    if ((((f86 >= 0.0) && (f86 <= 1.0)) && (f87 >= 0.0)) && (f87 <= 1.0))
    {
        f89 = f82 + (f84 * f85);
        f88 = f81 + f85;
    }
    else
    {
        f89 = f82;
        f88 = f81;
    }
    vec2 f90 = ((vec2(-0.16686917841434478759765625, -0.5135705471038818359375) * f4) * f5) + VARYING0;
    vec4 f91 = texture(iChannel0Texture, f90);
    float f92 = f91.w;
    float f93 = f90.x;
    float f94 = f90.y;
    float f95;
    vec4 f96;
    if ((((f93 >= 0.0) && (f93 <= 1.0)) && (f94 >= 0.0)) && (f94 <= 1.0))
    {
        f96 = f89 + (f91 * f92);
        f95 = f88 + f92;
    }
    else
    {
        f96 = f89;
        f95 = f88;
    }
    vec2 f97 = ((vec2(0.16686917841434478759765625, -0.5135705471038818359375) * f4) * f5) + VARYING0;
    vec4 f98 = texture(iChannel0Texture, f97);
    float f99 = f98.w;
    float f100 = f97.x;
    float f101 = f97.y;
    float f102;
    vec4 f103;
    if ((((f100 >= 0.0) && (f100 <= 1.0)) && (f101 >= 0.0)) && (f101 <= 1.0))
    {
        f103 = f96 + (f98 * f99);
        f102 = f95 + f99;
    }
    else
    {
        f103 = f96;
        f102 = f95;
    }
    vec2 f104 = ((vec2(0.436869204044342041015625, -0.3174040615558624267578125) * f4) * f5) + VARYING0;
    vec4 f105 = texture(iChannel0Texture, f104);
    float f106 = f105.w;
    float f107 = f104.x;
    float f108 = f104.y;
    float f109;
    vec4 f110;
    if ((((f107 >= 0.0) && (f107 <= 1.0)) && (f108 >= 0.0)) && (f108 <= 1.0))
    {
        f110 = f103 + (f105 * f106);
        f109 = f102 + f106;
    }
    else
    {
        f110 = f103;
        f109 = f102;
    }
    vec2 f111 = ((vec2(0.7651021480560302734375, 0.18858073651790618896484375) * f4) * f5) + VARYING0;
    vec4 f112 = texture(iChannel0Texture, f111);
    float f113 = f112.w;
    float f114 = f111.x;
    float f115 = f111.y;
    float f116;
    vec4 f117;
    if ((((f114 >= 0.0) && (f114 <= 1.0)) && (f115 >= 0.0)) && (f115 <= 1.0))
    {
        f117 = f110 + (f112 * f113);
        f116 = f109 + f113;
    }
    else
    {
        f117 = f110;
        f116 = f109;
    }
    vec2 f118 = ((vec2(0.58982646465301513671875, 0.522540628910064697265625) * f4) * f5) + VARYING0;
    vec4 f119 = texture(iChannel0Texture, f118);
    float f120 = f119.w;
    float f121 = f118.x;
    float f122 = f118.y;
    float f123;
    vec4 f124;
    if ((((f121 >= 0.0) && (f121 <= 1.0)) && (f122 >= 0.0)) && (f122 <= 1.0))
    {
        f124 = f117 + (f119 * f120);
        f123 = f116 + f120;
    }
    else
    {
        f124 = f117;
        f123 = f116;
    }
    vec2 f125 = ((vec2(0.279428660869598388671875, 0.7367928028106689453125) * f4) * f5) + VARYING0;
    vec4 f126 = texture(iChannel0Texture, f125);
    float f127 = f126.w;
    float f128 = f125.x;
    float f129 = f125.y;
    float f130;
    vec4 f131;
    if ((((f128 >= 0.0) && (f128 <= 1.0)) && (f129 >= 0.0)) && (f129 <= 1.0))
    {
        f131 = f124 + (f126 * f127);
        f130 = f123 + f127;
    }
    else
    {
        f131 = f124;
        f130 = f123;
    }
    vec2 f132 = ((vec2(-0.094982899725437164306640625, 0.78225457668304443359375) * f4) * f5) + VARYING0;
    vec4 f133 = texture(iChannel0Texture, f132);
    float f134 = f133.w;
    float f135 = f132.x;
    float f136 = f132.y;
    float f137;
    vec4 f138;
    if ((((f135 >= 0.0) && (f135 <= 1.0)) && (f136 >= 0.0)) && (f136 <= 1.0))
    {
        f138 = f131 + (f133 * f134);
        f137 = f130 + f134;
    }
    else
    {
        f138 = f131;
        f137 = f130;
    }
    vec2 f139 = ((vec2(-0.4476350247859954833984375, 0.64851129055023193359375) * f4) * f5) + VARYING0;
    vec4 f140 = texture(iChannel0Texture, f139);
    float f141 = f140.w;
    float f142 = f139.x;
    float f143 = f139.y;
    float f144;
    vec4 f180;
    if ((((f142 >= 0.0) && (f142 <= 1.0)) && (f143 >= 0.0)) && (f143 <= 1.0))
    {
        f180 = f138 + (f140 * f141);
        f144 = f137 + f141;
    }
    else
    {
        f180 = f138;
        f144 = f137;
    }
    vec2 f146 = ((vec2(-0.6977393627166748046875, 0.3662018477916717529296875) * f4) * f5) + VARYING0;
    vec4 f147 = texture(iChannel0Texture, f146);
    float f148 = f147.w;
    float f149 = f146.x;
    float f150 = f146.y;
    float f151;
    vec4 f181;
    if ((((f149 >= 0.0) && (f149 <= 1.0)) && (f150 >= 0.0)) && (f150 <= 1.0))
    {
        f181 = f180 + (f147 * f148);
        f151 = f144 + f148;
    }
    else
    {
        f181 = f180;
        f151 = f144;
    }
    vec2 f153 = ((vec2(-0.78799998760223388671875, 4.4644126152591019802973182351025e-16) * f4) * f5) + VARYING0;
    vec4 f154 = texture(iChannel0Texture, f153);
    float f155 = f154.w;
    float f156 = f153.x;
    float f157 = f153.y;
    float f158;
    vec4 f182;
    if ((((f156 >= 0.0) && (f156 <= 1.0)) && (f157 >= 0.0)) && (f157 <= 1.0))
    {
        f182 = f181 + (f154 * f155);
        f158 = f151 + f155;
    }
    else
    {
        f182 = f181;
        f158 = f151;
    }
    vec2 f160 = ((vec2(-0.6977393627166748046875, -0.3662018477916717529296875) * f4) * f5) + VARYING0;
    vec4 f161 = texture(iChannel0Texture, f160);
    float f162 = f161.w;
    float f163 = f160.x;
    float f164 = f160.y;
    float f165;
    vec4 f183;
    if ((((f163 >= 0.0) && (f163 <= 1.0)) && (f164 >= 0.0)) && (f164 <= 1.0))
    {
        f183 = f182 + (f161 * f162);
        f165 = f158 + f162;
    }
    else
    {
        f183 = f182;
        f165 = f158;
    }
    vec2 f167 = ((vec2(-0.4476350247859954833984375, -0.64851129055023193359375) * f4) * f5) + VARYING0;
    vec4 f168 = texture(iChannel0Texture, f167);
    float f169 = f168.w;
    float f170 = f167.x;
    float f171 = f167.y;
    float f172;
    vec4 f184;
    if ((((f170 >= 0.0) && (f170 <= 1.0)) && (f171 >= 0.0)) && (f171 <= 1.0))
    {
        f184 = f183 + (f168 * f169);
        f172 = f165 + f169;
    }
    else
    {
        f184 = f183;
        f172 = f165;
    }
    vec2 f174 = ((vec2(-0.094982899725437164306640625, -0.78225457668304443359375) * f4) * f5) + VARYING0;
    vec4 f175 = texture(iChannel0Texture, f174);
    float f176 = f175.w;
    float f177 = f174.x;
    float f178 = f174.y;
    float f179;
    vec4 f185;
    if ((((f177 >= 0.0) && (f177 <= 1.0)) && (f178 >= 0.0)) && (f178 <= 1.0))
    {
        f185 = f184 + (f175 * f176);
        f179 = f172 + f176;
    }
    else
    {
        f185 = f184;
        f179 = f172;
    }
    vec2 f181 = ((vec2(0.279428660869598388671875, -0.7367928028106689453125) * f4) * f5) + VARYING0;
    vec4 f182 = texture(iChannel0Texture, f181);
    float f183 = f182.w;
    float f184 = f181.x;
    float f185 = f181.y;
    float f186;
    vec4 f186;
    if ((((f184 >= 0.0) && (f184 <= 1.0)) && (f185 >= 0.0)) && (f185 <= 1.0))
    {
        f186 = f185 + (f182 * f183);
        f186 = f179 + f183;
    }
    else
    {
        f186 = f185;
        f186 = f179;
    }
    vec2 f188 = ((vec2(0.58982646465301513671875, -0.522540628910064697265625) * f4) * f5) + VARYING0;
    vec4 f189 = texture(iChannel0Texture, f188);
    float f190 = f189.w;
    float f191 = f188.x;
    float f192 = f188.y;
    float f193;
    vec4 f187;
    if ((((f191 >= 0.0) && (f191 <= 1.0)) && (f192 >= 0.0)) && (f192 <= 1.0))
    {
        f187 = f186 + (f189 * f190);
        f193 = f186 + f190;
    }
    else
    {
        f187 = f186;
        f193 = f186;
    }
    vec2 f195 = ((vec2(0.7651021480560302734375, -0.18858073651790618896484375) * f4) * f5) + VARYING0;
    vec4 f196 = texture(iChannel0Texture, f195);
    float f197 = f196.w;
    float f198 = f195.x;
    float f199 = f195.y;
    float f200;
    vec4 f188;
    if ((((f198 >= 0.0) && (f198 <= 1.0)) && (f199 >= 0.0)) && (f199 <= 1.0))
    {
        f188 = f187 + (f196 * f197);
        f200 = f193 + f197;
    }
    else
    {
        f188 = f187;
        f200 = f193;
    }
    vec2 f202 = ((vec2(1.0, 0.0) * f4) * f5) + VARYING0;
    vec4 f203 = texture(iChannel0Texture, f202);
    float f204 = f203.w;
    float f205 = f202.x;
    float f206 = f202.y;
    float f207;
    vec4 f189;
    if ((((f205 >= 0.0) && (f205 <= 1.0)) && (f206 >= 0.0)) && (f206 <= 1.0))
    {
        f189 = f188 + (f203 * f204);
        f207 = f200 + f204;
    }
    else
    {
        f189 = f188;
        f207 = f200;
    }
    vec2 f209 = ((vec2(0.93247222900390625, 0.3612416684627532958984375) * f4) * f5) + VARYING0;
    vec4 f210 = texture(iChannel0Texture, f209);
    float f211 = f210.w;
    float f212 = f209.x;
    float f213 = f209.y;
    float f214;
    vec4 f215;
    if ((((f212 >= 0.0) && (f212 <= 1.0)) && (f213 >= 0.0)) && (f213 <= 1.0))
    {
        f215 = f189 + (f210 * f211);
        f214 = f207 + f211;
    }
    else
    {
        f215 = f189;
        f214 = f207;
    }
    vec2 f216 = ((vec2(0.73900890350341796875, 0.673695623874664306640625) * f4) * f5) + VARYING0;
    vec4 f217 = texture(iChannel0Texture, f216);
    float f218 = f217.w;
    float f219 = f216.x;
    float f220 = f216.y;
    float f221;
    vec4 f222;
    if ((((f219 >= 0.0) && (f219 <= 1.0)) && (f220 >= 0.0)) && (f220 <= 1.0))
    {
        f222 = f215 + (f217 * f218);
        f221 = f214 + f218;
    }
    else
    {
        f222 = f215;
        f221 = f214;
    }
    vec2 f223 = ((vec2(0.4457383453845977783203125, 0.8951632976531982421875) * f4) * f5) + VARYING0;
    vec4 f224 = texture(iChannel0Texture, f223);
    float f225 = f224.w;
    float f226 = f223.x;
    float f227 = f223.y;
    float f228;
    vec4 f229;
    if ((((f226 >= 0.0) && (f226 <= 1.0)) && (f227 >= 0.0)) && (f227 <= 1.0))
    {
        f229 = f222 + (f224 * f225);
        f228 = f221 + f225;
    }
    else
    {
        f229 = f222;
        f228 = f221;
    }
    vec2 f230 = ((vec2(0.09226836264133453369140625, 0.995734155178070068359375) * f4) * f5) + VARYING0;
    vec4 f231 = texture(iChannel0Texture, f230);
    float f232 = f231.w;
    float f233 = f230.x;
    float f234 = f230.y;
    float f235;
    vec4 f236;
    if ((((f233 >= 0.0) && (f233 <= 1.0)) && (f234 >= 0.0)) && (f234 <= 1.0))
    {
        f236 = f229 + (f231 * f232);
        f235 = f228 + f232;
    }
    else
    {
        f236 = f229;
        f235 = f228;
    }
    vec2 f237 = ((vec2(-0.273662984371185302734375, 0.961825668811798095703125) * f4) * f5) + VARYING0;
    vec4 f238 = texture(iChannel0Texture, f237);
    float f239 = f238.w;
    float f240 = f237.x;
    float f241 = f237.y;
    float f242;
    vec4 f243;
    if ((((f240 >= 0.0) && (f240 <= 1.0)) && (f241 >= 0.0)) && (f241 <= 1.0))
    {
        f243 = f236 + (f238 * f239);
        f242 = f235 + f239;
    }
    else
    {
        f243 = f236;
        f242 = f235;
    }
    vec2 f244 = ((vec2(-0.602634608745574951171875, 0.798017203807830810546875) * f4) * f5) + VARYING0;
    vec4 f245 = texture(iChannel0Texture, f244);
    float f246 = f245.w;
    float f247 = f244.x;
    float f248 = f244.y;
    float f249;
    vec4 f250;
    if ((((f247 >= 0.0) && (f247 <= 1.0)) && (f248 >= 0.0)) && (f248 <= 1.0))
    {
        f250 = f243 + (f245 * f246);
        f249 = f242 + f246;
    }
    else
    {
        f250 = f243;
        f249 = f242;
    }
    vec2 f251 = ((vec2(-0.850217163562774658203125, 0.52643215656280517578125) * f4) * f5) + VARYING0;
    vec4 f252 = texture(iChannel0Texture, f251);
    float f253 = f252.w;
    float f254 = f251.x;
    float f255 = f251.y;
    float f256;
    vec4 f257;
    if ((((f254 >= 0.0) && (f254 <= 1.0)) && (f255 >= 0.0)) && (f255 <= 1.0))
    {
        f257 = f250 + (f252 * f253);
        f256 = f249 + f253;
    }
    else
    {
        f257 = f250;
        f256 = f249;
    }
    vec2 f258 = ((vec2(-0.9829730987548828125, 0.18374951183795928955078125) * f4) * f5) + VARYING0;
    vec4 f259 = texture(iChannel0Texture, f258);
    float f260 = f259.w;
    float f261 = f258.x;
    float f262 = f258.y;
    float f263;
    vec4 f264;
    if ((((f261 >= 0.0) && (f261 <= 1.0)) && (f262 >= 0.0)) && (f262 <= 1.0))
    {
        f264 = f257 + (f259 * f260);
        f263 = f256 + f260;
    }
    else
    {
        f264 = f257;
        f263 = f256;
    }
    vec2 f265 = ((vec2(-0.9829730987548828125, -0.18374951183795928955078125) * f4) * f5) + VARYING0;
    vec4 f266 = texture(iChannel0Texture, f265);
    float f267 = f266.w;
    float f268 = f265.x;
    float f269 = f265.y;
    float f270;
    vec4 f271;
    if ((((f268 >= 0.0) && (f268 <= 1.0)) && (f269 >= 0.0)) && (f269 <= 1.0))
    {
        f271 = f264 + (f266 * f267);
        f270 = f263 + f267;
    }
    else
    {
        f271 = f264;
        f270 = f263;
    }
    vec2 f272 = ((vec2(-0.850217163562774658203125, -0.52643215656280517578125) * f4) * f5) + VARYING0;
    vec4 f273 = texture(iChannel0Texture, f272);
    float f274 = f273.w;
    float f275 = f272.x;
    float f276 = f272.y;
    float f277;
    vec4 f278;
    if ((((f275 >= 0.0) && (f275 <= 1.0)) && (f276 >= 0.0)) && (f276 <= 1.0))
    {
        f278 = f271 + (f273 * f274);
        f277 = f270 + f274;
    }
    else
    {
        f278 = f271;
        f277 = f270;
    }
    vec2 f279 = ((vec2(-0.602634608745574951171875, -0.798017203807830810546875) * f4) * f5) + VARYING0;
    vec4 f280 = texture(iChannel0Texture, f279);
    float f281 = f280.w;
    float f282 = f279.x;
    float f283 = f279.y;
    float f284;
    vec4 f285;
    if ((((f282 >= 0.0) && (f282 <= 1.0)) && (f283 >= 0.0)) && (f283 <= 1.0))
    {
        f285 = f278 + (f280 * f281);
        f284 = f277 + f281;
    }
    else
    {
        f285 = f278;
        f284 = f277;
    }
    vec2 f286 = ((vec2(-0.273662984371185302734375, -0.961825668811798095703125) * f4) * f5) + VARYING0;
    vec4 f287 = texture(iChannel0Texture, f286);
    float f288 = f287.w;
    float f289 = f286.x;
    float f290 = f286.y;
    float f291;
    vec4 f292;
    if ((((f289 >= 0.0) && (f289 <= 1.0)) && (f290 >= 0.0)) && (f290 <= 1.0))
    {
        f292 = f285 + (f287 * f288);
        f291 = f284 + f288;
    }
    else
    {
        f292 = f285;
        f291 = f284;
    }
    vec2 f293 = ((vec2(0.09226836264133453369140625, -0.995734155178070068359375) * f4) * f5) + VARYING0;
    vec4 f294 = texture(iChannel0Texture, f293);
    float f295 = f294.w;
    float f296 = f293.x;
    float f297 = f293.y;
    float f298;
    vec4 f299;
    if ((((f296 >= 0.0) && (f296 <= 1.0)) && (f297 >= 0.0)) && (f297 <= 1.0))
    {
        f299 = f292 + (f294 * f295);
        f298 = f291 + f295;
    }
    else
    {
        f299 = f292;
        f298 = f291;
    }
    vec2 f300 = ((vec2(0.4457383453845977783203125, -0.8951632976531982421875) * f4) * f5) + VARYING0;
    vec4 f301 = texture(iChannel0Texture, f300);
    float f302 = f301.w;
    float f303 = f300.x;
    float f304 = f300.y;
    float f305;
    vec4 f306;
    if ((((f303 >= 0.0) && (f303 <= 1.0)) && (f304 >= 0.0)) && (f304 <= 1.0))
    {
        f306 = f299 + (f301 * f302);
        f305 = f298 + f302;
    }
    else
    {
        f306 = f299;
        f305 = f298;
    }
    vec2 f307 = ((vec2(0.73900890350341796875, -0.673695623874664306640625) * f4) * f5) + VARYING0;
    vec4 f308 = texture(iChannel0Texture, f307);
    float f309 = f308.w;
    float f310 = f307.x;
    float f311 = f307.y;
    float f312;
    vec4 f313;
    if ((((f310 >= 0.0) && (f310 <= 1.0)) && (f311 >= 0.0)) && (f311 <= 1.0))
    {
        f313 = f306 + (f308 * f309);
        f312 = f305 + f309;
    }
    else
    {
        f313 = f306;
        f312 = f305;
    }
    vec2 f314 = ((vec2(0.93247222900390625, -0.3612416684627532958984375) * f4) * f5) + VARYING0;
    vec4 f315 = texture(iChannel0Texture, f314);
    float f316 = f315.w;
    float f317 = f314.x;
    float f318 = f314.y;
    float f319;
    vec4 f320;
    if ((((f317 >= 0.0) && (f317 <= 1.0)) && (f318 >= 0.0)) && (f318 <= 1.0))
    {
        f320 = f313 + (f315 * f316);
        f319 = f312 + f316;
    }
    else
    {
        f320 = f313;
        f319 = f312;
    }
    _entryPointOutput = f320 * clamp(1.0 / (f319 + 0.001000000047497451305389404296875), 0.0, 1.0);
}

//$$iChannel0Texture=s0
//$$iChannel1Texture=s1
