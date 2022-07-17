# Shader初级

```cpp
Shader "FirstShader"
	SubShader {
		pass {
      			struct VertexIn {
                		float3 position : POSITION;
                		float3 normal   : NORMAL;
            		};
            		struct VertexOut {
                		float4 SVPosition : SV_POSITION;
                		float3 position   : VOUT_POSITION;
                		float3 normal     : VOUT_NORMAL;
            		};
            		VertexOut vert(VertexIn vin) {
                		VertexOut vout;
                		float4 worldPosition = mul(unity_ObjectToWorld, float4(vin.position, 1.0));
                		vout.SVPosition = mul(UNITY_MATRIX_VP, worldPosition);
                		vout.position = worldPosition.xzy;
                		vout.normal = mul((float3x3)transpose(unity_WorldToObject), vin.normal);
                		return vout;
           	 	}
            		float4 frag(VertexOut pin) : SV_Target {
                		return float4(pin.normal * 0.5 + 0.5, 1.0);
            		}
			CGEND
		}
	}
```

上面我们指定了顶点输入结构体 `VertexIn` 其中 Unity 默认支持下面的属性

* `POSITION` 位置
* `TANGENT` 切线
* `NORMAL` 法线
* `TEXCOORD0` uv0
* `TEXCOORD1` uv1
* `TEXCOORD2` UV2
* `TEXCOORD3` uv3
* `COLOR` 顶点颜色

## 内置 include 文件

在 unity 中提供了 .cginc 文件, 可以使用 `include` 指令把这些文件包含. 这样可以 unity 提供的变量和帮助函数

```glsl
CGPROGRAM
    #include "UnityCG.cginc"
CGEND    
```

| 文件名                    | 描述                                                         |
| ------------------------- | ------------------------------------------------------------ |
| UnityCG.cginc             | 最常使用的帮助函数, 宏和结构体                               |
| UnityShaderVariable.cginc | 自动包含进来                                                 |
| Lighting.cginc            | 内置的各种光照模型, 如果编写 Surface Shader 会自动包含进来   |
| HlslSupoort.cginc         | 编写 UnityShader 时, 会自动包含进来, 声明了很多跨平台的宏和定义 |

**UnityCG.cginc 中一些常用的帮助函数**

| 函数名                                           | 描述                                                         |
| ------------------------------------------------ | ------------------------------------------------------------ |
| `float3 WorldSpaceViewDir(float4 v)`             | 输入一个模型空间的位置, 返回世界空间中从该点到摄像机的观察方向 |
| `float3 ObjSpaceViewDir(float4 v)`               | 输入一个模型空间的顶点位置, 返回模型空间中从该点到摄像机的观察方向 |
| `float3 WorldSpaceLightDir(float4 v)`            | 返回世界空间中的 L 方向(没有归一化)                          |
| `float3 ObjSpaceLightDir(float4 v)`              | 返回模型空间中的 L 方向(没有归一化)                          |
| `float3 UnityObjectToWorldNormal(float3 normal)` | 输入模型空间的法线, 返回世界空间中法线                       |
| `float3 UnityObjectToWorldDir(float3 dir)`       | 把方向从模型空间变换到世界空间                               |
| `float3 UnityWOrldToObjectDir(float3 dir)`       | 把方向从世界空间转换到模型空间                               |

## Unity 中的环境光

unity 提供了宏 `UNITY_LIGHTMODEL_AMBIENT` 可以得到环境光的颜色和强度

标准的顶点光照

```glsl
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "Unlit/PixelLevel"
{
    Properties
    {
        uLightStrength ("Albedo", Range(0.0, 1.0)) = 1.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "lightModel" = "ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            struct VertexIn {
                float3 position : POSITION;
                float3 normal   : NORMAL;
            };

            struct VertexOut {
                float4 SVPosition : SV_POSITION;
                float3 position   : VOUT_POSITION;
                float3 normal     : VOUT_NORMAL;
            };

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, float4(vin.position, 1.0));
                vout.SVPosition = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = mul(vin.normal, (float3x3)unity_WorldToObject);
                return vout;
            }

            fixed uLightStrength;
            float4 frag(VertexOut pin) : SV_Target {
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.rgb;

                fixed3 N = normalize(pin.normal);
                fixed3 L = normalize(_WorldSpaceLightPos0.xzy);
                float3 diffuse = _LightColor0.rgb * saturate(dot(N, L));

                fixed3 V = normalize(_WorldSpaceCameraPos.xyz - pin.position);
                fixed3 H = normalize(V + L);
                float3 specular = _LightColor0.rgb * pow(saturate(dot(N, H)), 256.0);

                float3 finalColor = ambient + diffuse + specular;
                return float4(finalColor, 1.0);
            }

            ENDCG
        }
    }
}

```



## 法线贴图示例

```glsl
// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Unlit/SingleTexture"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _BumpTex ("Texture", 2D) = "default_nmap" {}
        _BumpSacle ("BumpSacle", float) = 1.0
        _Color ("Color", Color) = (1.0, 1.0, 1.0, 1.0)
        _Specular ("Specular", Color) = (1.0, 1.0, 1.0, 1.0)
        _Gloss ("Gloss", Range(8.0, 256.0)) = 64.0
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "LightModel"="ForwardBase" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
            #include "UnityCG.cginc"
            #include "Lighting.cginc"

            sampler2D _MainTex;
            sampler2D _BumpTex;
            fixed4 _Color;
            float4 _MainTex_ST;
            float4 _BumpTex_ST;
            fixed4 _Specular;
            fixed _BumpSacle;
            float _Gloss;

       
            struct VertexIn {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float4 tangent  : TANGENT;
                float2 texcoord : TEXCOORD0;
            };

            struct VertexOut {
                float4 SVPosition : SV_POSITION;
                float3 position   : VOUT_POSITION;
                float3 normal     : VOUT_NORMAL;
                float4 tangent    : VOUT_TANGENT;
                float2 texcoord   : VOUT_TEXCOORD0;
            };

            VertexOut vert(VertexIn vin) {
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                VertexOut vout;
                vout.SVPosition = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = UnityObjectToWorldNormal(vin.normal);
                vout.tangent.xyz = UnityObjectToWorldNormal(vin.tangent.xyz);
                vout.tangent.w = vin.tangent.w;
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
                return vout;
            }

            fixed3 NormalSampleToWorldSpace(VertexOut pin) {
                fixed3 normal = UnpackNormal(tex2D(_BumpTex, pin.texcoord));
                normal.xy *= _BumpSacle;
                normal = normalize(normal);
                fixed3 T = normalize(pin.tangent.xyz);
                fixed3 N = normalize(pin.normal);
                fixed3 B = cross(T, N) * pin.tangent.w;
                float3x3 TBN = float3x3(T, B, N);
                return mul(TBN, normal);
            }

            float4 frag(VertexOut pin) : SV_Target {
                float4 albedo = tex2D(_MainTex, pin.texcoord).rgba;
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz * albedo.rgb;

                // fixed3 N = normalize(pin.normal);
                fixed3 N = NormalSampleToWorldSpace(pin);
                fixed3 L = normalize(_WorldSpaceLightPos0.xyz);
                fixed  diff = saturate(dot(N, L));
                float3 diffuse = diff * _LightColor0.rgb * albedo.rgb * _Color;

                fixed3 V = normalize(UnityWorldSpaceViewDir(pin.position));
                fixed3 H = normalize(V + L);
                fixed  spec = pow(saturate(dot(N, H)), _Gloss);
                float3 specular = spec * _LightColor0.rgb * albedo.rgb * _Specular;

                float3 finalColor = ambient + diffuse + specular;
                return float4(finalColor, albedo.a);
            }

            ENDCG
        }
    }
    Fallback "Specular"
}

```



## 渐变纹理

提供一张纹理. 控制漫反射光照的结果

```glsl


float3 N = ...;
float3 L = ...;
float halfLambert = dot(N, L) * 0.5 + 0.5;
float2 diffuseTexcoord = float2(halfLambert, halfLambert);
float3 diffuseColor = tex2D(_RampTex, diffuseTexcoord);				
float3 diffuse = diffuseColor * _LightColor.rgb * _Color;
```



## 混合

alpha test 和 transparent 队列

```cc
Tags { "RenderType"="AlphaTest" ... }	
Tags { "RenderType"="Transparent" ... }
```

透明测试函数

```cc
void clip(float4 x) {
    if (any(x < 0))
        disacrd;
}
```



## Blend 命令

| 语义                                             | 描述                            |
| ------------------------------------------------ | ------------------------------- |
| Blend Off                                        | 关闭混合                        |
| Blend SrcFactor DstFactor                        | 开启混合并设置混合因子          |
| Blend SrcFactor DstFactor, SrcFactorA DstFactorA | 和上面一样, 但是 A 通道特别处理 |
| BlendOp BlendOperation                           | 使用逻辑运算混合                |

## 混合因子

| 参数             | 描述                 |
| ---------------- | -------------------- |
| One              | 因子为1              |
| Zero             | 因子为0              |
| SrcColor         | 因子为源颜色的颜色值 |
| SrcAlpha         | 因为为源颜色透明值   |
| DstColor         | 因子为目标颜色值     |
| DstAlpha         | 因子为目标颜色透明度 |
| OneMinusSrcColor | 因子为 1 - SrcColor  |
| OneMinusSrcAlpha | 因子为 1 - SrcAlpha  |
| OneMinusDstColor | 因子为 1 - DstColor  |
| OneMinusDstAlpha | 因子为 1 - DstAlpha  |

## 混合操作

| 操作   | 描述          |
| ------ | ------------- |
| Add    | 相加          |
| Sub    | Src - Dst     |
| RevSub | Dst - Src     |
| Min    | Min(Src, Dst) |
| Max    | Max(Src, Dst) |

## 常见的混合类型

```glsl
正常混合
// BlendOp Add		默认为相加
Blend SrcAlpha OneMinusSrcAlpha			
    
柔和相加    
// BlendOp Add		默认为相加    
Blend OneMinusDstColor One
    
正片叠底(相乘)
// BlendOp Add		默认为相加    
Blend DstColor Zero
    
两倍相乘
// BlendOp Add		默认为相加    
Blend DstColor SrcColor

变暗
BlendOp Min
Blend One One
    
变亮
BlendOp Max
Blend One One

滤色
// BlendOp Add		默认为相加        
Blend OneMinusDstColor One

线性减淡
// BlendOp Add		默认为相加        
Blend One One    
```



## 双面混合示例

```glsl
Shader "Unlit/AlphaTest"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Color ("Color", Color) = (1, 1, 1, 1)
        _Cutoff ("Alpha Cutoff", Range(0, 1)) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "LightModel"="ForwardBase" "IgonraProjection" = "True" }
        LOD 100

        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Front 
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed  _Cutoff;

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.SVPosition = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = UnityObjectToWorldNormal(vin.normal);
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
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
                float spec = pow(saturate(dot(N, H)), 256.0);
                float3 specular = spec * _LightColor0.rgb * albedo.rgb;        

                float3 finalColor = ambient + diffuse + specular;
                return float4(finalColor, albedo.a);        
            }
            ENDCG
        }


        Pass
        {
            Blend SrcAlpha OneMinusSrcAlpha
            Cull Back 
            ZWrite Off

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog
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
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed4 _Color;
            fixed  _Cutoff;

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.SVPosition = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = UnityObjectToWorldNormal(vin.normal);
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
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
                float spec = pow(saturate(dot(N, H)), 256.0);
                float3 specular = spec * _LightColor0.rgb * albedo.rgb;        

                float3 finalColor = ambient + diffuse + specular;
                return float4(finalColor, albedo.a);        
            }
            ENDCG
        }
    }
    Fallback "Color"
}

```

