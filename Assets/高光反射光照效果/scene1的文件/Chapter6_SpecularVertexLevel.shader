Shader "Unity Shaders Book/Chapter6/SpecularVertexLevel"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
        _Specular("Specular", Color) = (1,1,1,1)//_Specular用于控制材质的高光反射颜色
        _Gloss("Gloss",Range(8.0,256)) = 20//_Gloss用于控制材质的高光反射区域大小，数值越大范围越小
    }
    SubShader
    {
        Pass{
            Tags {"LightMode"="ForwardBase"}
        }
      
        CGPROGRAM
        #pragma vertex vert
        #pragma fragment frag

        #include "Lighting.cginc"

        fixed4 _Diffuse;//用fixed4存储是因为它是一个颜色值，包含了RGBA四个分量，每个分量的范围是0到1，使用fixed4可以更高效地存储和处理颜色数据。
        fixed4 _Specular;//同样使用fixed4存储高光反射颜色，因为它也是一个颜色值，包含了RGBA四个分量。
        float _Gloss;//使用float存储高光反射区域大小，因为它是一个单一的数值，不需要存储多个分量。

        struct a2v{
            float4 vertex : POSITION;
            float3 normal : NORMAL;
        };

        struct v2f{
            float4 pos : SV_POSITION;
            fixed4 color : COLOR;
        };
        
        v2f vert(a2v v){
            v2f o;
            0.pos = mul(UNITY_MATRIX_MVP, v.vertex);//mul()是一个函数，用于执行矩阵乘法运算。在这里，它将顶点位置v.vertex与UNITY_MATRIX_MVP矩阵相乘，得到变换后的顶点位置o.pos。UNITY_MATRIX_MVP是一个内置的矩阵，包含了模型、视图和投影矩阵的组合，用于将顶点从模型空间转换到裁剪空间。
            fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//UNITY_LIGHTMODEL_AMBIENT是一个内置的变量，表示环境光的颜色。通过访问它的xyz分量，我们可以获取环境光的RGB颜色值，并将其存储在ambient变量中。
            fixed3 worldNormal = normalize(mul(v.normal,(float3x3)_World2Object));//将顶点的法线向量v.normal从对象空间转换到世界空间。首先，将v.normal与_World2Object矩阵相乘，得到在世界空间中的法线向量。然后，使用normalize函数对结果进行归一化，以确保法线向量的长度为1。
            fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//将光源位置_WorldSpaceLightPos0从世界空间转换为一个方向向量。首先，访问_WorldSpaceLightPos0的xyz分量，得到光源在世界空间中的位置。然后，使用normalize函数对结果进行归一化，以获得一个单位长度的方向向量worldLightDir。
            fixed3 diffuse=_LightColor.rgb*_Diffuse.rgb*saturate(dot(worldNormal,worldLightDir));//计算漫反射颜色。首先，使用dot函数计算法线向量worldNormal和光线方向worldLightDir之间的点积，得到一个表示光照强度的值。然后，使用saturate函数将该值限制在0到1之间，以确保漫反射颜色不会超过最大值。最后，将光源颜色_LightColor.rgb与材质的漫反射颜色_Diffuse.rgb相乘，并乘以之前计算的光照强度，得到最终的漫反射颜色diffuse。
            fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));//计算反射方向。首先，使用reflect函数计算入射光线-worldLightDir相对于法线worldNormal的反射方向。然后，使用normalize函数对结果进行归一化，以确保反射方向的长度为1。
            fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(_Object2World, v.vertex).xyz);//计算视线方向。首先，将顶点位置v.vertex从对象空间转换到世界空间，得到顶点在世界空间中的位置。然后，使用_WorldSpaceCameraPos表示摄像机在世界空间中的位置，计算摄像机位置与顶点位置之间的向量。最后，使用normalize函数对结果进行归一化，以获得一个单位长度的视线方向viewDir。
            fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);//计算高光反射颜色。首先，使用dot函数计算反射方向reflectDir和视线方向viewDir之间的点积，得到一个表示高光强度的值。然后，使用saturate函数将该值限制在0到1之间，以确保高光反射颜色不会超过最大值。接下来，使用pow函数将高光强度提升到_Gloss次幂，以控制高光反射区域的大小。最后，将光源颜色_LightColor.rgb与材质的高光反射颜色_Specular.rgb相乘，并乘以之前计算的高光强度，得到最终的高光反射颜色specular。
            o.color = ambient + diffuse + specular;//将环境光、漫反射颜色和高光反射颜色相加，得到最终的顶点颜色o.color。
            return o;
        }
        
        fixed4 frag(v2f i) ：SV_Target{
            return fixed4(i.color,1.0);//将顶点颜色i.color转换为一个包含RGBA分量的fixed4类型，并将alpha分量设置为1，表示完全不透明。最终返回这个颜色值作为片段着色器的输出。
        }

        ENDCG
    }
    FallBack "Specular"
}
