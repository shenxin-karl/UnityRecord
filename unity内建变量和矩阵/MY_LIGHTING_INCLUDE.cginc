#ifndef MY_LIGHTING_INCLUDE
#define MY_LIGHTING_INCLUDE
#include "UnityPBSLighting.cginc"

#include "UnityCG.cginc"
#include "UnityPBSLighting.cginc"
#include "AutoLight.cginc"
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
#if defined(VERTEXLIGHT_ON)
	float3 vertexLightColor : TEXCOORD3;
#endif
};

sampler2D _MainTex;
float4 _MainTex_ST;
fixed _Metallic;
fixed _Smoothness;
float4 _DiffuseAlbedo;

void ComputeVertexLightColor(inout VertexOut vout) {
#if defined(VERTEXLIGHT_ON)
	vout.vertexLightColor = Shade4PointLights(
	    unity_4LightPosX0, unity_4LightPosY0, unity_4LightPosZ0,
	    unity_LightColor[0], unity_LightColor[1], unity_LightColor[2], unity_LightColor[3],
		unity_4LightAtten0, vout.normal, vout.position
	);
#endif
}

VertexOut vert(VertexIn vin) {
    VertexOut vout;
    float4 worldPosition = mul(unity_ObjectToWorld, vin.position);
    vout.pos = mul(UNITY_MATRIX_VP, worldPosition);
    vout.position = worldPosition.xyz;
    vout.normal = UnityObjectToWorldNormal(vin.normal);
    vout.texcoord = TRANSFORM_TEX(vin.texcoord, _MainTex);
    ComputeVertexLightColor(vout);
    return vout;
}

UnityLight CreateLight(VertexOut pin, float3 N) {
    UnityLight light;
    float3 L = normalize(UnityWorldSpaceLightDir(pin.position));
    UNITY_LIGHT_ATTENUATION(attenuation, 0, pin.position);
    light.color = _LightColor0.rgb * attenuation;
    light.dir = L;
    light.ndotl = saturate(dot(N, L));
    return light;
}

UnityIndirect CreateUnityIndirectLight(VertexOut pin, float3 albedo) {
	UnityIndirect indirectLight;
    indirectLight.diffuse = 0;
    indirectLight.specular = 0;

#ifdef FORWARD_BASE
	indirectLight.diffuse = max(0, ShadeSH9(float4(pin.normal, 1.0)));
#endif

#if defined(VERTEXLIGHT_ON)
	indirectLight.diffuse += pin.vertexLightColor;
#endif
    return indirectLight;
}

float4 frag(VertexOut pin) : SV_TARGET {
    float3 V = normalize(UnityWorldSpaceViewDir(pin.position));
    float3 N = normalize(pin.normal);
    
    float3 albedo = tex2D(_MainTex, pin.texcoord).rgb * _DiffuseAlbedo.rgb;

    float3 fresnelR0;
    float oneMinusReflectivity;
    albedo = DiffuseAndSpecularFromMetallic( 
        albedo,
        _Metallic,
        fresnelR0,
        oneMinusReflectivity
    );

    UnityLight light = CreateLight(pin, N);
    UnityIndirect indirectLight = CreateUnityIndirectLight(pin, albedo);

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

#endif