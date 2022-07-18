// Upgrade NOTE: replaced '_LightMatrix0' with 'unity_WorldToLight'

Shader "Unlit/ForwardRedering"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8, 256)) = 64
    }
    SubShader
    {
      Pass {
        // ForwardBase 负责渲染 非重要光源, 唯一的方向光
        Tags { "LightMode" = "ForwardBase" }

        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag
        #pragma multi_compile_fwdbase
        #pragma multi_compile _ VERTEXLIGHT_ON
        #include "UnityCG.cginc"
        #include "Lighting.cginc"

            struct VertexIn {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOut {
                float4 SVPosition : SV_POSITION;
                float3 position   : VOUT_POSITION;
                float3 normal     : VOUT_NORMAL;
                float2 texcoord   : VOUT_TEXCOORD0;
                float3 lightColor : VOUT_LIGHTCOLOR;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Gloss;

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.SVPosition = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = normalize(UnityObjectToWorldNormal(vin.normal));
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);

                // 计算非重要光源点光源
                vout.lightColor = Shade4PointLights(unity_4LightPosX0, 
                    unity_4LightPosY0, 
                    unity_4LightPosZ0, 
                    unity_LightColor[0], 
                    unity_LightColor[1], 
                    unity_LightColor[2], 
                    unity_LightColor[3], 
                    unity_4LightAtten0,
                    vout.position,
                    vout.normal
                );
                return vout;
            }

            fixed4 frag (VertexOut pin) : SV_Target {
                fixed4 textureColor = tex2D(_MainTex, pin.texcoord);

                float4 albedo = textureColor * _Color;
                float3 ambient = albedo.rgb * UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 N = UnityObjectToWorldNormal(pin.normal);
                fixed3 L = normalize(UnityWorldSpaceLightDir(pin.position));
                float  diff = saturate(dot(N, L));
                float3 diffuse = diff * _LightColor0.rgb * albedo.rgb;

                fixed3 V = normalize(UnityWorldSpaceViewDir(pin.position));
                fixed3 H = normalize(V + L);
                float spec = pow(saturate(dot(N, H)), _Gloss);
                float3 specular = spec * _LightColor0.rgb * albedo.rgb;        
                float3 notImportantLightColor = albedo.rgb * pin.lightColor;

                // 计算非重要方向光与聚光灯
                float3 shColor = albedo.rgb  * max(ShadeSH9(float4(pin.normal, 1.0)), 0);

                float3 finalColor = ambient + diffuse + specular + notImportantLightColor + shColor;
                return float4(finalColor, albedo.a);        
            }
        ENDCG
      }

      Pass {
        Tags { "LightMode" = "ForwardAdd" }
        Blend One One
        ZWrite Off

        CGPROGRAM
        #pragma multi_compile_fwdadd
        #pragma vertex vert
        #pragma fragment frag
        #include "UnityCG.cginc"
        #include "Lighting.cginc"
        #include "AutoLight.cginc"

        struct VertexIn {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOut {
                float4 SVPosition : SV_POSITION;
                float3 position   : VOUT_POSITION;
                float3 normal     : VOUT_NORMAL;
                float2 texcoord   : VOUT_TEXCOORD0;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            float _Gloss;

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.SVPosition = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = normalize(UnityObjectToWorldNormal(vin.normal));
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
                return vout;
            }

            fixed4 frag (VertexOut pin) : SV_Target {
                fixed4 textureColor = tex2D(_MainTex, pin.texcoord);

                float4 albedo = textureColor * _Color;

                fixed3 N = UnityObjectToWorldNormal(pin.normal);
                fixed3 L = normalize(UnityWorldSpaceLightDir(pin.position));

                fixed atten =  1.0;
                #if defined (POINT)
                    float3 lightCoord = mul(unity_WorldToLight, float4(pin.position, 1.0)).xyz;
                    atten = tex2D(_LightTexture0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #elif defined(SPOT)
                    float4 lightCoord = mul(unity_WorldToLight, float4(pin.position, 1.0));
                    atten = (lightCoord.z > 0) * tex2D(_LightTexture0, lightCoord.xy / lightCoord.w + 0.5).w * tex2D(_LightTextureB0, dot(lightCoord, lightCoord).rr).UNITY_ATTEN_CHANNEL;
                #endif

                fixed3 lightColor = _LightColor0.rgb * atten;
                float  diff = saturate(dot(N, L));
                float3 diffuse = diff * lightColor * albedo.rgb;

                fixed3 V = normalize(UnityWorldSpaceViewDir(pin.position));
                fixed3 H = normalize(V + L);
                float spec = pow(saturate(dot(N, H)), _Gloss);
                float3 specular = spec * lightColor * albedo.rgb;        


                float3 finalColor = diffuse + specular;
                return float4(finalColor, albedo.a);        
            }
        ENDCG
      }
    }
    Fallback "Color"
}
