Shader "Custom/TestTexture"
{
    Properties
    {
  
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Tex01("Albedo01 (RGB)", 2D) = "white" {}
        _Tex02("Albedo02 (RGB)", 2D) = "white" {}
        _Tex03("Albedo03 (RGB)", 2D) = "white" {}
        _Tex04("Albedo04 (RGB)", 2D) = "white" {}
        _Tex05("Albedo05 (RGB)", 2D) = "white" {}
        _Tex06("Albedo06 (RGB)", 2D) = "white" {}
        _Tex07("Albedo07 (RGB)", 2D) = "white" {}

        _Tex08("Albedo08 (RGB)", 2D) = "white" {}
        _Tex09("Albedo09 (RGB)", 2D) = "white" {}
        _Tex10("Albedo10(RGB)", 2D) = "white" {}
        _Tex11("Albedo11 (RGB)", 2D) = "white" {}
        _Tex12("Albedo12 (RGB)", 2D) = "white" {}
        _Tex13("Albedo13 (RGB)", 2D) = "white" {}
        _Tex14("Albedo14 (RGB)", 2D) = "white" {}
        _Tex15("Albedo15 (RGB)", 2D) = "white" {}
        

    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        Pass {
            Name "FORWARD"
            Tags {
                "LightMode"="LightweightForward"
            }
            HLSLPROGRAM

            // Use shader model 3.0 target, to get nicer looking lighting
            #pragma target 3.0
            #pragma vertex vert
            #pragma fragment frag


            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitInput.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/Shaders/LitForwardPass.hlsl"

            sampler2D _MainTex;
            sampler2D _Tex01;
            sampler2D _Tex02;
            sampler2D _Tex03;
            sampler2D _Tex04;
            sampler2D _Tex05;
            sampler2D _Tex06;
            sampler2D _Tex07;

            sampler2D _Tex08;
            sampler2D _Tex09;
            sampler2D _Tex10;
            sampler2D _Tex11;
            sampler2D _Tex12;
            sampler2D _Tex13;
            sampler2D _Tex14;
            sampler2D _Tex15;

            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float2 texcoord0 : TEXCOORD0;
                float2 lightmapUV   : TEXCOORD1;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float3 normalDir : TEXCOORD2;
                float3 tangentDir : TEXCOORD3;
                float3 bitangentDir : TEXCOORD4;
                //v.2.0.7
                float mirrorFlag : TEXCOORD5;
    
                DECLARE_LIGHTMAP_OR_SH(lightmapUV, vertexSH, 6);
                half4 fogFactorAndVertexLight   : TEXCOORD7; // x: fogFactor, yzw: vertex light
				float4 shadowCoord              : TEXCOORD8;
                float4 positionCS               : TEXCORRD9;
                UNITY_VERTEX_INPUT_INSTANCE_ID
                UNITY_VERTEX_OUTPUT_STEREO
    
            };
            
            #define _WorldSpaceLightPos0 _MainLightPosition
            #define _LightColor0 _MainLightColor
            inline float4 UnityObjectToClipPosInstanced(in float3 pos)
            {
            //    return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorldArray[unity_InstanceID], float4(pos, 1.0)));
                  // todo. right?
                  return mul(UNITY_MATRIX_VP, mul(unity_ObjectToWorld, float4(pos, 1.0)));
            }
            inline float4 UnityObjectToClipPosInstanced(float4 pos)
            {
                return UnityObjectToClipPosInstanced(pos.xyz);
            }
            #define UnityObjectToClipPos UnityObjectToClipPosInstanced
            
            inline float3 UnityObjectToWorldNormal( in float3 norm )
            {
            #ifdef UNITY_ASSUME_UNIFORM_SCALING
                return UnityObjectToWorldDir(norm);
            #else
                // mul(IT_M, norm) => mul(norm, I_M) => {dot(norm, I_M.col0), dot(norm, I_M.col1), dot(norm, I_M.col2)}
                return normalize(mul(norm, (float3x3)unity_WorldToObject));
            #endif
            }
            VertexOutput vert (VertexInput v) 
            {
                VertexOutput o = (VertexOutput)0;
    
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o);
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
    
                o.uv0 = v.texcoord0;
                o.normalDir = UnityObjectToWorldNormal(v.normal);
                o.tangentDir = normalize( mul( unity_ObjectToWorld, float4( v.tangent.xyz, 0.0 ) ).xyz );
                o.bitangentDir = normalize(cross(o.normalDir, o.tangentDir) * v.tangent.w);
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                float3 lightColor = _LightColor0.rgb;
                o.pos = UnityObjectToClipPos( v.vertex );
                float3 crossFwd = cross(UNITY_MATRIX_V[0], UNITY_MATRIX_V[1]);
                o.mirrorFlag = dot(crossFwd, UNITY_MATRIX_V[2]) < 0 ? 1 : -1;
                    //
    
                float3 positionWS = TransformObjectToWorld(v.vertex);
                float4 positionCS = TransformWorldToHClip(positionWS);
                half3 vertexLight = VertexLighting(o.posWorld, o.normalDir);
                half fogFactor = ComputeFogFactor(positionCS.z);
    
                OUTPUT_LIGHTMAP_UV(v.lightmapUV, unity_LightmapST, o.lightmapUV);
                OUTPUT_SH(o.normalDir.xyz, o.vertexSH);
    
                o.fogFactorAndVertexLight = half4(fogFactor, vertexLight);
                o.positionCS = positionCS;
                o.shadowCoord = TransformWorldToShadowCoord(o.posWorld);
    
    
                return o;
            }
                
            float4 frag(VertexOutput i, half facing : VFACE) : SV_TARGET
            {
                half4 col = tex2D(_MainTex, i.uv0);
                 // apply fog
                
                return col;
            }    
            ENDHLSL
        }
    }
}
