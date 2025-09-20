Shader "Unlit/MuiltiUVShader"
{
    Properties
    {
        _BaseMap ("Base Map", 2D) = "white" {}
        _BaseColor ("Base Color", Color) = (1, 1, 1, 1)

        //Dropdown to pick with UV set the Base Map uses
        [KeywordEnum(UV0, UV1)] _UVSET ("UV Set", Float) = 0
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
                float2 uv0 : TEXCOORD0; //Mesh UV channel 0
                float2 uv1 : TEXCOORD1; //Mesh UV channel 1
            };

            struct v2f
            {
                float4 positionHCS : SV_POSITION;
                float2 uv : TEXCOORD0; //default UV chosen by the dropdown
            };

            //Textures and Samplers
            TEXTURE2D (_BaseMap);
            SAMPLER(sampler_BaseMap);

            //Material (SRP Batcher)
            CBUFFER_START(UnityPerMaterial)
                float4 _BaseColor;
                float4 _BaseMap_ST; //tilting and offset
            CBUFFER_END

            v2f vert (Attributes i)
            {
                v2f o;
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
                return half4(baseTex.rgb * _BaseColor.rgb, 1.0);
            }
            ENDHLSL
        }
    }
    FallBack Off
}
