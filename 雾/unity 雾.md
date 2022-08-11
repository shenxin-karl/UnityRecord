# unity 雾

## 前向渲染中的雾

1. 要开启 unity 雾, 首先要使用下面的 shader 变体

```cc
// 额外带来 FOG_LINEAR FOG_EXP FOG_EXP2
#pragma multi_compile_fog
```

2. 使用 UNITY_CALC_FOG_FACTOR_RAW 获取雾的因子

```cc
float4 applyFog(float4 color, VertexOut pin) {
    // 如果没有开启雾
    #if !defined(FOG_LINEAR) && !defined(FOG_EXP) && !defined(FOG_EXP2)
        return color;
    #endif
    
    float viewDistance = lenght(_WorldSpaceCameraPos.xyz - pin.worldPosition);
    UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
    return lerp(unity_FogColor, color, saturate(unityFogFactor));
}
```

3. 在 PS 的输出前调用 `applyFog` 函数

```cc
float4 frag(VertexOut pin) : SV_Target {
    float4 color = ...;
    return applyFog(color, pin);
}
```



## 基于深度的雾

![img](depth-distance.png)

使用深度的雾是一个平面, 使用距离的雾是个圆

如果使用深度的雾, 那么 vs 需要插值裁剪空间深度过来. 同时传递给 `UNITY_CALC_FOG_FACTOR_RAW` 宏应该是深度, 而不是距离

最后在 ps 中使用 `UNITY_Z_0_FAR_FROM_CLIPSPACE` 获取真正的深度

```cc
struct VertexOut {
    float4 pos 			 : SV_POSITION;
#if defined(FOG_DEPTH)
    float4 worldPosition : TEXCOORD1;			// 开启深度雾时, worldPosition 的 w 记录裁剪空间中深度
#else
    float3 worldPosition : TEXCOORD0;
#endif
};

VertexOut vert (VertexIn vin) {
	VertexOut vout;
	vout.pos = UnityObjectToClipPos(vin.vertex);
	vout.worldPos.xyz = mul(unity_ObjectToWorld, vin.vertex);
	#if FOG_DEPTH
		vout.worldPos.w = vout.pos.z;
	#endif
	...
}

float4 ApplyFog (float4 color, VertexOut pin) {
	float viewDistance = length(_WorldSpaceCameraPos - i.worldPos.xyz);
	#if FOG_DEPTH
        // UNITY_Z_0_FAR_FROM_CLIPSPACE 屏蔽反向z, 左右手坐标系 获取深度的方式
		viewDistance = UNITY_Z_0_FAR_FROM_CLIPSPACE(i.worldPos.w);
	#endif
	UNITY_CALC_FOG_FACTOR_RAW(viewDistance);
	return lerp(unity_FogColor, color, saturate(unityFogFactor));
}
```

## 前向多光源雾

在使用前向多光源时, 每个光源都会应用雾, 最后可能会导致很亮

因此解决方案是在附加通道中始终使用黑色。这样，雾就使附加光的作用减弱，而又不会使雾本身变亮

```cc
float4 ApplyFog (float4 color, VertexOut pin) {
	...
    float3 fogColor = 0;
    #if defined(FORWARD_BASE_PASS)
		fogColor = unity_FogColor.rgb;
    #endif
	color.rgb = lerp(fogColor, color.rgb, saturate(unityFogFactor));
    return color;
}
```





## 延迟雾

要在延迟渲染中应用雾, 在要相机中添加一个脚本, 使用后处理的方式渲染



1. 创建一个 C# 脚本, 为当前相机添加这个脚本
2. 编写延迟渲染的 Fog shder

做个全屏幕的后处理, 采样深度图, 计算雾

