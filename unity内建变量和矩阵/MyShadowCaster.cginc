// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

#ifndef MY_SHADOW_CASTER
#define MY_SHADOW_CASTER
#include "UnityCG.cginc"


// 点光源阴影
#if defined(SHADOWS_CUBE)
	struct VertexIn {
		float3 vertex : POSITION;
	};

	struct VertexOut {
		float4 position : SV_POSITION;
		float3 lightVec : TEXCOORD0;
	};

	VertexOut vert(VertexIn vin) {
		VertexOut vout;
		vout.position = UnityObjectToClipPos(vin.vertex);
		vout.lightVec = _LightPositionRange.xyz - mul(unity_ObjectToWorld, vin.vertex).xyz;
		return vout;
	}

	float4 frag(VertexOut pin) : SV_Target {
		float depth = length(pin.lightVec) + unity_LightShadowBias.x;			// 这里计算 Bias
		depth *= _LightPositionRange.w;
		return UnityEncodeCubeShadowDepth(depth);								// 点光源的 ShadowMap 是立方体贴图, 所以这里会将 depth 解码到4个通道里面
	}

// 方向光和聚光灯阴影
#else
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
#endif


#endif