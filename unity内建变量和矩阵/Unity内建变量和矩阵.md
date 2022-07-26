# 学习Shader需要的数学基础

# 坐标系

![image-20220715001314259](image-20220715001314259.png)

**除了在观察空间中, 其他都是在左手系**

## Unity 内置的变换矩阵

| 变量名                | 描述                               |
| --------------------- | ---------------------------------- |
| `UNITY_MATRIX_MVP`    | `project * view * model`           |
| `UNITY_MATRIX_MV`     | `view * model`                     |
| `UNITY_MATRIX_V`      | `view`                             |
| `UNITY_MATRIX_P`      | `project`                          |
| `UNITY_MATRIX_VP`     | `project * view`                   |
| `UNITY_MATRIX_T_MV`   | `inverse(view * model)`            |
| `UNITY_MATRIX_IT_MV`  | `transpose(inverse(view * model))` |
| `unity_ObjectToWorld` | `model`                            |
| `unity_WorldToObject` | `inverse(model)`                   |

## Unity 内置变量

| 变量名                        | 类型       | 描述                                                         |
| ----------------------------- | ---------- | ------------------------------------------------------------ |
| `_WorldSpaceCameraPos`        | `float3`   | 相机世界空间中的位置                                         |
| `_ProjectionParams`           | `float4`   | `x = 1.0`<br />`y = Near`<br />`z = Far`<br />`w = 1.0 + 1.0/Far` |
| `_ScreenParams`               | `float4`   | `x = width`<br />`y = height`<br />`z = 1 + 1 / width`<br />`y = 1 + 1 / height` |
| `_ZBufferParams`              | `float4`   | `x = 1 - Far/Near`<br />`y = Far/Near`<br />`z = x / Far` <br />`w = y / Far` |
| `unity_OrthoParams`           | `float4`   | x = width, y = height, z 没有定义, w = 1.0 是正交相机, w = 0.0 透视投影 |
| `unity_CameraProject`         | `float4x4` | 相机中的投影矩阵                                             |
| `unity_CameraInvProject`      | `float4x4` | 相机投影逆矩阵                                               |
| `unity_CameraWorldClipPlanes` | `float4`   | 相机在 6 个裁剪屏幕在世界空间下的等式<br />按照 左, 右, 上, 下, 近, 远 |

## **Unity 光照相关函数**

```cc
// forward
// 仅用于前向渲染中. 计算前四个点光源的光照, 它的参数是已经打包进矢量的光照数据. 分别是
float3 Shade4PointLights (
    float4 lightPosX, 
    float4 lightPosY, 
    float4 lightPosZ,
    float3 lightColor0, 
    float3 lightColor1, 
    float3 lightColor2, 
    float3 lightColor3,
    float4 lightAttenSq,
    float3 pos, 
    float3 normal
)

// forward & forward add
float3 UnityObjectToWorldNormal(float3 normal);				// 变换到世界空间法线
float3 UnityObjectToWorldDir(float3 dir);				// 变换到世界空间中的向量
float3 UnityWorldSpaceLightDir(float3 wolrdPosition);		// 获取世界空间L方向, 需要归一化
float3 UnityWorldSpaceViewDir(float3 wolrdPosition);		// 获取世界空间V方向, 需要归一化

// forward add
float3 ShadeSH9(float3 normal);								// 获取球谐函数
```

## 变换纹理相关宏

```cc
#define TRANSFORM_TEX(InTexcoord, Sampler2D)
```



**Unity 光照相关变量**

需要包含头文件 `UnityCG.cginc`  `UnityLightingCommon.cginc`

| 名称                                                         | 类型       | 描述                                                         |
| ------------------------------------------------------------ | ---------- | ------------------------------------------------------------ |
| `_LightColor0`                                               | `float4`   | 改 Pass 处理的逐像素光源的颜色                               |
| `_WorldSpaceLightPos0`                                       | `float4`   | 如果 `w != 0` 是点光源, 否则是方向光                         |
| `_LightMatrix0`                                              | `float4x4` | 光空间矩阵                                                   |
| `unity_4LightPosX0`,`unity_4LightPosY0`, `unity_4LightPosZ0` | `float4`   | 仅用于 `Base Pass` 中前四个 4 非重要的点光源在世界空间的位置 |
| `unity_4LightAtten0`                                         | `float4`   | 仅用于 `Base Pass` 存储了前 4 个非重要的点光源衰减因子       |
| `unity_LightColor`                                           | `half[4]`  | 仅用于 `Base Pass` 存储了前 4 个非重要的点光源的颜色         |

## Unity 物理着色

```cc
#include "UnityPBSLighting.cginc"
#pragma target 3.0

inline half3 DiffuseAndSpecularFromMetallic(
	half3 albedo,
    half metallic,
    out half3 specColor,
    out half oneMinusReflectivity
);

struct UnityLight {
    float3 color;
    float3 dir;
    float ndotl;
};

struct UnityIndirect {
  	float3 diffuse;
    float3 specular;
};

float4 UNITY_BRDF_PBS(
	float3 albedo,
    float3 fresnelaR0,
    float oneMinusReflectivity,
    float smoothness,
    float3 N,
    float3 V,
    UnityLight light,
    UnityIndirect indirectLight,
);
```



示例

```cc
Shader "Unlit/UnityPBS"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Metallic ("Metallic", Range(0, 1)) = 0.5
        _Smoothness ("Smoothness", Range(0, 1)) = 0.5
        _DiffuseAlbedo ("DiffuseAlbedo", Color) = (1, 1, 1, 1)
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityPBSLighting.cginc"
            #pragma target 3.0

            struct VertexIn {
                float4 position : POSITION;
                float3 normal   : NORMAL;
                float2 texcoord : TEXCOORD;
            };

            struct VertexOut {
                float4 pos      : SV_POSITION;
                float3 position : TEXCOORD0;
                float3 normal   : TEXCOORD1;
                float2 texcoord : TEXCOORD2;
            };

            sampler2D _MainTex;
            float4 _MainTex_ST;
            fixed _Metallic;
            fixed _Smoothness;
            float4 _DiffuseAlbedo;

            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
                vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
                vout.position = worldPosition.xyz;
                vout.normal = UnityObjectToWorldNormal(vin.normal);
                vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
                return vout;
            }

            float4 frag(VertexOut pin) : SV_TARGET {
                float3 N = normalize(pin.normal);
                float3 L = normalize(UnityWorldSpaceLightDir(pin.position));
                float3 V = normalize(UnityWorldSpaceViewDir(pin.position));
                
                float3 albedo = tex2D(_MainTex, pin.texcoord).rgb * _DiffuseAlbedo.rgb;
                float3 ambient = _LightColor0.rgb * albedo;

                float3 fresnelR0;
                float oneMinusReflectivity;
                albedo = DiffuseAndSpecularFromMetallic( 
                    albedo,
                    _Metallic,
                    fresnelR0,
                    oneMinusReflectivity
                );

                UnityLight light;
                light.color = _LightColor0.rgb;
                light.dir = L;
                light.ndotl = saturate(dot(N, L));

                UnityIndirect indirectLight;
                indirectLight.diffuse = ambient;
                indirectLight.specular = 0;

                return UNITY_BRDF_PBS(
                    albedo,
                    fresnelR0,
                    oneMinusReflectivity,
                    _Smoothness,
                    N,
                    V,
                    light,
                    indirectLight
                );
            }
            ENDCG
        }
    }
}

```

## 光照衰减相关

头文件

```cc
#include "AutoLight.cginc"

#define UNITY_LIGHT_ATTENUATION(
	varName,
	input,
	worldPosition
)
```

## 非重要光源

**顶点光源**

计算多光源时, **ForwardBase Pass** 中需要加入 

**#pragma multi_compile _ VERTEXLIGHT_ON**

```cc
// 计算顶点的四个非重要光源, 返回顶点颜色
float3 Shade4PointLights(
	float4 unity_4LightPosX0,
    float4 unity_4LightPosY0,
    float4 unity_4LightPosZ0,
    float3 unity_LightColor0,
    float3 unity_LightColor1,
    float3 unity_LightColor2,
    float3 unity_LightColor3,
    float4 unity_4LightAtten0,
    float3 worldNormal,
    float3 worldPosition
);
// example
vout.vertexLightColor = Shade4PointLights(
    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
    unity_LightColor[0], unity_LightColor[1], unity_LightColor[2], unity_LightColor[3],
	unity_4LightAtten0, vout.normal, vout.position
);
```

**球谐光照**

```cc
float3 ShadeSH9(float4 worldNormal);

// example
float3 diffuseColor += max(0, ShaderSH9(float4(pin.normal, 1.0)));
```



## 完整的顶点多光源例子

 [MY_LIGHTING_INCLUDE.cginc](MY_LIGHTING_INCLUDE.cginc) 

 [MultiLIghtShader.shader](MultiLIghtShader.shader) 



## 法线贴图相关

```cc
#include "UnityStandardUtils.cginc"

// 解压法线贴图. 法线可能是被压缩过的
float3 UnpackNormal(float4 packedNormal);
float3 UnpackScaleNormal(float4 packedNormal, float bumpScale);			

// 混合两个法线(Unity提供)
float3 BlendNormals(float3 n1, float3 n2) {
    return normalize(float3(n1.xy + n2.xy, n1.z * n2.x));
}			
```

完整的法线贴图例子

 [BumpMapShader.shader](BumpMapShader.shader) 





## 投射阴影

```cc
// 返回偏移后的裁剪空间位置
// clipPos 裁剪空间位置
float4 UnityApplyLinearShadowBias(float4 clipPos) {
   	clipPos.z += saturate(unity_LightShadowBias.x / clipPos.w);
    float clamped = max(clipPos.z, clipPos.w * UNITY_NEAR_CLIP_VALUE);
    clipPos.z = lerp(clipPos.z, clamped, unity_LightShadowBias.y);
    return clipPos;
}

// 返回应用法线偏移后的裁剪空间的位置
// modelPos 模型位置
// modelNormal 模型法线
float4 UnityClipSpaceShadowCasterPos(float3 modelPos, float3 modelNormal);
```

例子

```cc
struct VertexIn {
	float3 vertex : POSITION;
	float3 normal : NORMAL;
};

float4 vert(VertexIn vin) : SV_POSITION {
	float4 clipPos = UnityClipSpaceShadowCasterPos(vin.vertex, vin.normal);
	return UnityApplyLinearShadowBias(clipPos);
}

float4 frag() : SV_Target {
	return float4(0.0, 0.0, 0.0, 1.0);
}
```



## 接受阴影

在接受阴影是, 在 **ForwardBase** 需要添加下面的变体, 同时包含头文件

```cc
#pragma multi_compile _ SHADOWS_SCREEN		// 阴影必须使用

#include "Lighting.cginc"
#include "AutoLight.cginc"
```

**1. `SHADOW_COORDS(n)` 在插值结构体中使用**

```cc
struct VertexIn {
  	float4 vertex : POSITION;			// 模型空间只能命名为 vertex  
};

struct VertexOut {
    float4 pos      : SV_POSITION;		// 要使用阴影宏时, 这个 SV_POSITION 只能命名为 pos
    float4 position : TEXCOORD0;
    float3 normal   : TEXCOORD1;
    float2 texcoord : TEXCOORD2;
    SHADOW_COORDS(3)					// 这里的 n 会被展开为 : TEXCOORD##n
}
```

**2. 在顶点结构体中使用 `TRANSFER_SHADOW(o)`**

```cc
VertexOut vert(VertexIn vin) {
    VertexOut vout;
   	...
	TRANSFER_SHADOW(vout);			// 这里做光空间的变换
    return vout;
}
```

**3. 片段着色器中获取衰减 `UNITY_LIGHT_ATTENUATION(var, input, worldPosition)`**

```cc
fixed4 frag(VertexOut pin) : SV_TARGET {
    ...
    UNITY_LIGHT_ATTENUATION(attenuation, pin, pin.position);
    return (diffuse + specular) * attenuation;
}
```

## 多阴影

默认情况下阴影只支持单个光源, 要支持多光源阴影时, 需要在 **ForwardAdd Pass** 中使用下面的指令

```cc
// #pragma multi_compile_fwdadd			// 替换 multi_compile_fwdadd
#pragam multi_compile_fwdadd_fullshadows
```

对于 **ForwardAdd Pass** 可能跑 **方向光, 聚光灯, 点光源**.



### 点光源阴影

当我们为点光源开启阴影时, 需要做额外处理

```cc
pass 
{
    Tags { "LightMode" = "ShadowCaster" }
    CGPROGRAM
    #pragma multi_compile_shadowcaster
    ...
    ENDCG       
}
```





点光源的 **ShadowCaster Pass** 是不同的, 完整例子如下



 [MyShadowCaster.cginc](MyShadowCaster.cginc) 



## 采样天空盒

头文件

```cc
#include "unity_SpecCube0.cginc"
```

采样函数

```cc
samplerCube unity_SpecCube0;			// 天空盒采样器

// 解码 HDR 值. 
// unity_SpecCube0_HDR 给 unity_SpecCube0 解码的变量
inline half3 DecodeHDR(half4 data, half4 decodeInstructions = unity_SpecCube0_HDR);

#define UNITY_SAMPLE_TEXCUBE(sampleCube, dir)			// 采样天空盒
#define UNITY_SAMPLE_TEXCUBE_LOD(sampleCube, dir, lod)	// 采样天空盒的 lod

// 提供粗糙度和采样向量, 帮我我们采样 天空盒
struct Unity_GlossyEnvironmentData {
	float roughness;
    float3 reflUVW;
};
half3 Unity_GlossyEnvironment(UNITY_ARGS_TEXCUBE(tex), half4 hdr, Unity_GlossyEnvironmentData glossIn);
```

**采样天空盒**

```cc
// 手动采样
float roughness = (1.0 - _Smoothness);
float lod = roughness * UNITY_SPECCUBE_LOD_STEPS;						// UNITY_SPECCUBE_LOD_STEPS 是天空盒的 LOD 级别. 使用 IBL 采样对应级别的 lod
float4 envColor = UNITY_SAMPLE_TEXCUBE_LOD(unity_SpecCube0, R, lod);
indirectLight.specular = DecodeHDR(envColor, unity_SpecCube0_HDR);

// Unity_GlossyEnvironment 函数帮助我们采样 
// UNITY_PASS_TEXCUBE 宏能够帮我们ch
Unity_GlossyEnvironmentData envData;
envData.roughness = 1 - _Smoothness;
envData.reflUVW = reflectionDir;
indirectLight.specular = Unity_GlossyEnvironment(
    UNITY_PASS_TEXCUBE(unity_SpecCube0), unity_SpecCube0_HDR, envData
);
```

