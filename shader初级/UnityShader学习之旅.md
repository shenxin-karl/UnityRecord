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
Shader "Unlit/VertexLevel"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1.0, 1.0, 1.0, 1.0)
    }
    SubShader
    {
        Tags { "LightMode"="ForwardBase" }
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
            fixed4 _Diffuse;
                
            struct VertexIn {
                float4 position : POSITION;
                float3 normal   : NORMAL;
            };

            struct VertexOut {
                float4 SVPosition : SV_POSITION;
                float3 color      : VOUT_COLOR;
            };
            
            VertexOut vert(VertexIn vin) {
                VertexOut vout;
                vout.SVPosition = UnityObjectToClipPos(vin.position);
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // unity_WorldToObject = inverse(model);    
                // mul(vin.normal, (float3x3)unity_WorldToObject) = mul(transpose(float3x3)unity_WorldToObject)), vin.normal);
                fixed3 worldNormal = mul(vin.normal, (float3x3)unity_WorldToObject);       
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));
                vout.color = diffuse + ambient; 
                return vout;
            }

            float4 frag(VertexOut pin) : SV_Target {
                return float4(pin.color, 1.0);
            }

            ENDCG
        }
    }
    FallBack "Diffuse"
}
```

