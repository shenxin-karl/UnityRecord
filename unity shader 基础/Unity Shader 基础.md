# Unity Shader 基础

## 属性定义

所有的属性都是通过下面的格式去定义

```txt
Properties {
	Name ("DisplayName", PropertyType) = DefaultValue;
}
```

实例化

| 属性名称        | 默认值的定义语法                 | 例子                                           |
| --------------- | -------------------------------- | ---------------------------------------------- |
| Int             | number                           | _Int("Int", Int) = 2                           |
| Float           | number                           | _Float("Float", Float) = 1.5                   |
| Range(min, max) | number                           | _Range("Range", Range(0.0, 5.0)) = 3.0         |
| Color           | (number, number, number, number) | _Color("Color", Color) = (1,  1, 1, 1)         |
| Vector          | (number, number, number, number) | _Vector("Vector", Vector) = (2, 3, 4, 5)       |
| 2D              | "defaultTexture" {}              | _2DTexture("2DTexture", 2D) = "white" {}       |
| Cube            | "defaultTexture" {}              | _CubeTexture("CubeTexture", Cube) = "white" {} |
| 3D              | "defaultTexture" {}              | _3D("3DTexture", 3D) = "black" {}              |

## 状态设置

| 状态名称 | 设置指令                                                     | 解释     |
| -------- | ------------------------------------------------------------ | -------- |
| Cull     | Cull [ Back \| Front \| Off ]                                | 剔除模式 |
| ZTest    | ZTest [ Less \| LEqual \| GEqual \| Equal \| NotEqual \| Always ] Greater | 深度测试 |
| ZWrite   | ZWrite [ On \| Off ]                                         | 深度写入 |
| Blend    | Blend SrcFactor DstFactor                                    | 混合模式 |

## 标签块

```tex
Tags { "TagName1" = "Value1", "TagName2" = "Value2" ... "TagNamen" = "Valuen" }
```

| 标签类型               | 说明                                              | 例子                                       |
| ---------------------- | ------------------------------------------------- | ------------------------------------------ |
| `Queue`                | 指定渲染队列                                      | `Tags { "Queue" = "Transparent" }`         |
| `RenderType`           | 着色器分类                                        | `Tags { "RenderType" = "Opaque" }`         |
| `DisableBatching`      | 关闭合批                                          | `Tags { "DisableBatching" = "True" }`      |
| `ForceNoShadowCasting` | 不产生阴影                                        | `Tags { "ForceNoShadowCasting" = "True" }` |
| `IgnoreProjector`      | 不受 Projector 影响                               | `Tags { "IgnoreProjector" = "True" }`      |
| `CanUseSpriteAtlas`    | 可以使用精灵图集                                  | `Tags { "CanUseSpriteAtlas" = "False" }`   |
| `PreviewType`          | 材质球预览shader的类型, 可以为 `"Plane" "SkyBox"` | `Tags { "PreviewType" = "Plane" }`         |

## Pass 语义块

```txt
Pass {
	Name = "MyPassName"
	UsePass = "MyShader/MYPASSNAME"		// 复用其他 Shader 的 Pass
	
}
```

## Fallback

```tex
Fallback "name"			// 如果 SubShader 不能执行就跑这个 shader
Fallback Off			// 如果 SubShader 不能执行就不执行这 shader
```

## UnityShader 示例

```glsl
Shader "Custom/Simple VertexFragment Shader" {
	SubShader {
		Pass {
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
				
            float4 vert(float4 v : POSITION) : SV_POSITION {
				return mul(UNITY_MATRIX_MVP, v);
            }
			
            float4 frag() : SV_Target {
                return float4(1.0, 0.0, 0.0, 1.0);
            }
            
			CGEND
		}
	}
}
```

