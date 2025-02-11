#version 110

#extension GL_ARB_shading_language_include : require
#include <EmitterParams.h>
#include <Globals.h>
uniform vec4 CB1[4];
uniform vec4 CB0[53];
attribute vec3 POSITION;
attribute vec3 TEXCOORD0;
attribute vec2 TEXCOORD5;
attribute vec2 TEXCOORD1;
attribute vec2 TEXCOORD2;
attribute vec4 TEXCOORD3;
attribute vec2 TEXCOORD4;
attribute float TEXCOORD6;
attribute vec3 TEXCOORD7;
varying vec3 VARYING0;
varying vec4 VARYING1;
varying vec2 VARYING2;
varying vec2 VARYING3;
varying float VARYING4;

void main()
{
    vec4 v0 = vec4(POSITION, 1.0);
    vec2 v1 = (TEXCOORD2 * 2.0) - vec2(1.0);
    vec2 v2 = TEXCOORD1 * vec2(0.00019175345369148999452590942382812, 3.0518509447574615478515625e-05);
    float v3 = v2.x;
    float v4;
    float v5;
    if (TEXCOORD6 <= 0.0)
    {
        float v6 = 1.0 - TEXCOORD6;
        v5 = 1.0 / v6;
        v4 = v6;
    }
    else
    {
        float v7 = 1.0 + TEXCOORD6;
        v5 = v7;
        v4 = 1.0 / v7;
    }
    float v8 = cos(v3);
    float v9 = sin(v3);
    vec4 v10 = vec4(0.0);
    v10.x = (v8 * TEXCOORD5.x) * v4;
    vec4 v11 = v10;
    v11.y = ((-v9) * TEXCOORD5.x) * v5;
    vec4 v12 = v11;
    v12.z = (v9 * TEXCOORD5.y) * v4;
    vec4 v13 = v12;
    v13.w = (v8 * TEXCOORD5.y) * v5;
    vec4 v14;
    if (0.0 == CB1[3].x)
    {
        v14 = (v0 + (CB0[4] * dot(v1, v13.xy))) + (CB0[5] * dot(v1, v13.zw));
    }
    else
    {
        vec4 v15;
        if (1.0 == CB1[3].x)
        {
            v15 = (v0 + (CB0[4] * dot(v1, v13.xy))) + (vec4(0.0, 1.0, 0.0, 0.0) * dot(v1, v13.zw));
        }
        else
        {
            float v16 = length(TEXCOORD0);
            vec4 v17;
            if (v16 > 9.9999997473787516355514526367188e-05)
            {
                vec3 v18 = TEXCOORD0 / vec3(v16);
                vec3 v19;
                vec3 v20;
                if (2.0 == CB1[3].x)
                {
                    v20 = normalize(cross(v18, CB0[6].xyz));
                    v19 = v18;
                }
                else
                {
                    vec3 v21 = normalize(cross(v18, vec3(0.0, 1.0, 0.0)));
                    v20 = normalize(cross(v21, v18));
                    v19 = v21;
                }
                v17 = (v0 + (vec4(v19, 0.0) * dot(v1, v13.xy))) + (vec4(v20, 0.0) * dot(v1, v13.zw));
            }
            else
            {
                v17 = v0;
            }
            v15 = v17;
        }
        v14 = v15;
    }
    vec4 v22 = v14 + (CB0[6] * CB1[1].x);
    mat4 v23 = mat4(CB0[0], CB0[1], CB0[2], CB0[3]);
    vec4 v24 = v14 * v23;
    vec3 v25 = vec3(0.0);
    v25.x = TEXCOORD2.x;
    vec3 v26 = v25;
    v26.y = TEXCOORD2.y;
    vec3 v27 = v26;
    v27.y = 1.0 - TEXCOORD2.y;
    vec3 v28 = v27;
    v28.z = length(CB0[7].xyz - v22.xyz);
    vec4 v29 = v22 * v23;
    vec4 v30 = v24;
    v30.z = (v29.z * v24.w) / v29.w;
    vec2 v31 = (TEXCOORD4 + ((TEXCOORD2 * (CB1[2].z - 1.0)) + vec2(0.5))) * CB1[2].xy;
    vec2 v32 = v31;
    v32.y = 1.0 - v31.y;
    vec2 v33 = CB1[3].zw * vec2(0.015625);
    vec2 v34 = clamp(v28.xy, v33, vec2(1.0) - v33);
    vec3 v35 = v28;
    v35.x = v34.x;
    vec3 v36 = v35;
    v36.y = v34.y;
    vec2 v37 = vec2(1.0) / CB1[3].zw;
    vec2 v38 = v36.xy * v37;
    float v39 = v38.x;
    vec3 v40 = v36;
    v40.x = v39;
    float v41 = v38.y;
    vec3 v42 = v40;
    v42.y = v41;
    float v43 = v37.x;
    vec3 v44 = v42;
    v44.x = v39 + (mod(TEXCOORD7.x, CB1[3].z) * v43);
    float v45 = v37.y;
    vec3 v46 = v44;
    v46.y = v41 + (floor(TEXCOORD7.x / CB1[3].z) * v45);
    vec2 v47 = v42.xy;
    v47.x = v39 + (mod(TEXCOORD7.y, CB1[3].z) * v43);
    vec2 v48 = v47;
    v48.y = v41 + (floor(TEXCOORD7.y / CB1[3].z) * v45);
    gl_Position = v30;
    VARYING0 = v46;
    VARYING1 = TEXCOORD3 * 0.0039215688593685626983642578125;
    VARYING2 = v32;
    VARYING3 = v48;
    VARYING4 = TEXCOORD7.z;
}

