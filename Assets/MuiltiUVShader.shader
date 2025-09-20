Shader "Unlit/MuiltiUVShader"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        //Dropdown to pick with UV set the Base Map uses
        [KeywordEnum(UV0, UV1)] _UVSET ("UV Set", Float) = 0

        //rim/fresnel demo
        _RimColor ("Rim Color", Color) = (1, 1, 1, 1)
        _RimPower ("Rim Power", Range (0.5, 8)) = 3
        _RimStrength ("Rim Strength", Range(0, 1)) = 0.5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" "Queue"="Geometry" "RenderPipeline"="UniversalRenderPipeline"}
        LOD 200

        Pass
        {
            Name "Unlit"
            Tags {"Lightmode"="UniversalForward"}

            HLSLPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            //Create keywords that match [KeywordEnum]
            #pragma shader_feature_local _UVSET_UV0 _UVSET_UV1

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            struct Attributes
            {
                float4 positionOS : POSITION;
                float3 normalOS : NORMAL;
                float2 uv0 : TEXCOORD0; //Mesh UV channel 0
                float2 uv1 : TEXCOORD1; //Mesh UV channel 1
            };

            struct v2f
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0; //default UV chosen by the dropdown

                float3 positionWS : TEXCOORD1;
                float3 normalWS : TEXCOORD2;
            };

            //Textures and Samplers
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);

            //Material (SRP Batcher)
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST; //tilting and offset
                float4 _RimColor;
                float _RimPower;
                float _RimStrength;
            CBUFFER_END

            v2f vert (Attributes i)
            {
                v2f o;
                
                float3 posWS = TransformObjectToWorld(i.positionOS.xyz);
                float3 nrmWS = TransformObjectToWorldNormal(i.normalOS);

                o.positionWS = posWS; //pass to frag
                o.normalWS = nrmWS;
                o.positionHCS = TransformObjectToHClip(i.positionOS.xyz);

                //choose UV set based on dropdown
                #if defined(_UVSET_UV1)
                    o.uv = TRANSFORM_TEX(i.uv1, _BaseMap);
                #else // _UVSET_UV0
                    o.uv = TRANSFORM_TEX(i.uv0, _BaseMap);
                #endif

                return o;
            }

            half4 frag (v2f i) : SV_Target
            {
                half4 baseTex = SAMPLE_TEXTURE2D(_BaseMap, sampler_BaseMap, i.uv);
                half3 color = baseTex.rgb * _BaseColor.rgb;

                //viewDir in URP
                //Get vector from surface point to cam
                float3 viewDirWS = GetWorldSpaceViewDir(i.positionWS);
                viewDirWS = SafeNormalize(viewDirWS);

                //Fresnel/rim using world space normal
                float3 n = SafeNormalize(i.normalWS);
                float ndotv = saturate(dot(n, viewDirWS));
                float fres = pow(1.0 - ndotv, _RimPower); //stronger at grazing angles
                color += (_RimColor.rgb * fres) * _RimStrength; //Additively boost rim

                return half4(color, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
