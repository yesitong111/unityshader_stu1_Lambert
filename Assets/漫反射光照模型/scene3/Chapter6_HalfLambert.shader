// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter 6/HalfLambert"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
    }
    /*
            定义了材质在 Inspector 中可调的属性。这里有一个属性：
            名称：_Diffuse（Shader 内部的变量名）
            显示名："Diffuse"（Inspector 中显示）
            类型：Color（颜色）
            默认值：(1,1,1,1) —— 即白色，不透明。
        */
    SubShader
    {
        Pass{
            Tags { "LightMode" = "ForwardBase" }//Tag "LightMode"="ForwardBase" 表示这个 Pass 用于前向渲染的基底光照通道（处理主光源与环境光，额外光通常用 ForwardAdd）
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"//包含 Unity 内置的光照/实用函数（GI、光照计算辅助宏等），方便实现灯光相关计算。
            fixed4  _Diffuse;//声明一个 uniform 变量，类型为四分量颜色，它应对应在 Properties 中定义的 _Diffuse（材质面板中可设置的颜色）。
            // 顶点输入结构体
            struct a2v
            {
                float4 vertex : POSITION;//顶点位置
                float3 normal : NORMAL;//顶点法线
            }; 
            // 顶点到片元的传递结构
            struct v2f
            {
                float4 pos : SV_POSITION;//裁剪空间位置
                float3 worldNormal : TEXCOORD0;//世界空间法线
            };
            v2f vert(a2v v)
            {
                v2f o;
                // 定义顶点着色器的输入a2v v（存储顶点位置、法线等模型空间的顶点数据），输出结构体v2f o（存储要传递给片元着色器、后续会被插值的数据）
                o.pos = UnityObjectToClipPos(v.vertex);//将顶点位置从对象空间变换到裁剪空间，UNITY_MATRIX_MVP是Unity内置的一个矩阵，表示模型-视图-投影矩阵的乘积。这个矩阵将顶点位置从对象空间（模型空间）变换到世界空间，再变换到视图空间，最后变换到裁剪空间。mul()函数用于执行矩阵与向量的乘法运算，这里将顶点位置v.vertex乘以MVP矩阵得到裁剪空间位置o.pos。
                o.worldNormal = mul(v.normal, (float3x3)unity_WorldToObject);//将法线从模型空间变换到世界空间，v.normal是模型空间下的法线，_World2Object是从世界空间到对象空间的变换矩阵，取其前三行三列得到旋转部分（法线是方向向量，等价于w=0的齐次坐标不需要平移变换，所以只需要3乘3），将法线乘以这个旋转矩阵即可得到世界空间下的法线。
                return o;
            }
            fixed4 frag(v2f i) : SV_Target//片元着色器，输入为顶点着色器传递的结构体v2f，输出为一个四分量颜色（RGBA），使用SV_Target语义表示这是渲染目标的输出。
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//获取环境光颜色，UNITY_LIGHTMODEL_AMBIENT是Unity内置的一个变量，表示当前场景的环境光颜色，取其xyz分量得到RGB颜色。
                fixed3 worldNormal = normalize(i.worldNormal);//将传入的世界空间法线进行归一化处理，确保其长度为1，以便后续的光照计算。
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//获取主光源的世界空间方向，_WorldSpaceLightPos0是Unity内置的一个变量，表示主光源的位置或方向（对于定向光是一个方向向量），取其xyz分量并归一化得到光照方向。
                fixed halfLambert = dot(worldNormal, worldLightDir) * 0.5 + 0.5;//计算半兰伯特漫反射系数，dot(worldNormal, worldLightDir)计算法线与光照方向的点积得到入射角的余弦值（范围[-1,1]），乘以0.5并加上0.5将结果映射到[0,1]之间，这样即使当光线背向表面时也会保留一定的漫反射亮度，避免背光面完全黑暗。
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * halfLambert;//计算漫反射分量，_LightColor0是Unity内置的一个变量，表示主光源的颜色，_Diffuse.rgb是材质的漫反射颜色，halfLambert是计算得到的半兰伯特漫反射系数。三者相乘得到该像素的漫反射光颜色。
                fixed3 color = ambient + diffuse;//将环境光和漫反射分量相加得到最终光照颜色。
                return fixed4(color, 1.0);//返回最终像素颜色，alpha分量设置为1.0表示完全不透明。RGB通道为计算得到的光照颜色。
            }
            ENDCG
        }
    }
    Fallback "Diffuse"//指定一个后备着色器，当当前平台不支持这个自定义着色器时，Unity 将使用内置的 Diffuse 着色器来渲染对象。这确保了在不支持自定义着色器的环境中，物体仍然能够正确显示。
}

/*半兰伯特（Half Lambert）模型是对标准兰伯特漫反射的改进：标准兰伯特用saturate(dot(N,L))将背光面截为0，而半兰伯特用 dot(N,L)*0.5+0.5 将[-1,1]映射到[0,1]，使背光面仍有一定亮度，整体过渡更柔和。本Shader在片元着色器中逐像素计算半兰伯特光照，因此属于逐像素光照，效果比逐顶点版本更平滑。*/
