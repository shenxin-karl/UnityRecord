Shader "Unlit/BumpMapShader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _DetailMap ("DetaiTexture", 2D) = "white" {}
        [NoScaleOffset] _NormalMap ("NormalMap", 2D) = "bump" {}
        [NoScaleOffset] _DetailNormalMap ("DetailNormalMap", 2D) = "bump" {}
        _BumpScale ("BumpScale", Float) = 1
        [Gamma] _Metaiilc ("Metaiilc", Range(0, 1)) = 0.5
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            Tags { "LightMode" = "ForwardBase" }

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"
            #include "UnityStandardUtils.cginc"
            #include "AutoLight.cginc"
            #pragma target 3.0

            sampler2D _MainTex;
            sampler2D _DetailMap;
            sampler2D _NormalMap;
            sampler2D _DetailNormalMap;
            float4 _MainTex_ST;
            float4 _DetailMap_ST;
            float _BumpScale;
            float _Metaiilc;
            float _Smoothness;

            struct VertexIn {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 texcoord : TEXCOORD0;
            };
           
            struct VertexOut {
                float4 pos      : SV_POSITION;
                float3 position : TEXCOORD0;
                float3 normal   : TEXCOORD1;
                float4 tangent  : TEXCOORD2;
                float4 texcoord : TEXCOORD3;
            };

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = UnityObjectToWorldNormal(vin.normal);
                vout.tangent = float4(UnityObjectToWorldDir(vin.tangent.xyz), vin.tangent.w);
                vout.texcoord.xy = TRANSFORM_TEX(vin.texcoord, _MainTex);
                vout.texcoord.zw = TRANSFORM_TEX(vin.texcoord, _DetailMap);
                return vout;
            }

            float3 SclickFresnel(float3 F0, float angleOfIncidence) {
                float cosTh = 1.0 - angleOfIncidence;
                return F0 + (1.0 - F0) * (cosTh * cosTh * cosTh * cosTh * cosTh);
            }

            void initFragmentNormal(inout VertexOut pin) {
                float3 mainNormal = UnpackScaleNormal(tex2D(_NormalMap, pin.texcoord.xy), _BumpScale);
                float3 detailNormal = UnpackScaleNormal(tex2D(_DetailNormalMap, pin.texcoord.zw), _BumpScale);
                float3 tangentSpaceNormal = BlendNormals(mainNormal, detailNormal);

                float3 N = normalize(pin.normal);
                float3 T = normalize(pin.tangent);
                float3 B = cross(N, T) * pin.tangent.w;
                pin.normal = T * tangentSpaceNormal.x +
                             B * tangentSpaceNormal.y + 
                             N * tangentSpaceNormal.z;
            } 

            float4 frag(VertexOut pin) : SV_Target {  
                initFragmentNormal(pin);
                float3 mainAlbedo = tex2D(_MainTex, pin.texcoord.xy);
                float3 detailAlbedo = tex2D(_DetailMap, pin.texcoord.zw);
                float3 albedo = mainAlbedo * detailAlbedo;

                float3 N = normalize(pin.normal);
                float3 L = UnityWorldSpaceLightDir(pin.position); 
                float NdotL = saturate(dot(N, L));

                float3 F0 = lerp(float3(0.04, 0.04, 0.04), albedo, _Metaiilc);
                float3 V = normalize(UnityWorldSpaceViewDir(pin.position));
                float3 H = normalize(V + L);
                float3 NdotH = saturate(dot(N, H));
                float m = max(_Smoothness * 512.0, 1.0);
                float3 roughnessFactor = (m + 2.0) / 8.0 * pow(NdotH, m);
                float3 fresnelFactor = SclickFresnel(F0, saturate(dot(H, V)));

                float3 specularAlbedo = roughnessFactor * fresnelFactor;
                float3 diffuseAlbedo = albedo * (1.0 - _Metaiilc);
                specularAlbedo = specularAlbedo / (specularAlbedo + 1.0);
                float3 directColor = (diffuseAlbedo + specularAlbedo) * NdotL * _LightColor0.rgb;

                float3 indirectDiffuse = ShadeSH9(float4(N, 1.0)) * albedo;
                float3 finalColor = directColor + indirectDiffuse;

                return float4(finalColor, 1.0);
            }
            ENDCG
        }
    }
    FallBack "Specular"
}
