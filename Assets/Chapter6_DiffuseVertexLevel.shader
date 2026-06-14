Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex_Level"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
    }
    Shader "Unity Shaders Book/Chapter 6/Diffuse Vertex_Level"
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
            }
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
                float3 color : COLOR;//顶点颜色
            };
            v2f vert(a2v v)
            {
                v2f o;
                // 将顶点从对象空间变换到裁剪空间
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
                // 计算顶点的漫反射光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//获取环境光颜色RGB
                fixed3 worldNormal = normalize(mul(v.normal,(float3x3)_World2Object)); //将法线从模型空间变换到世界空间，v.normal是模型空间下的法线，_World2Object是从世界空间到对象空间的变换矩阵，取其前三行三列得到旋转部分（法线是方向向量，等价于w=0的齐次坐标不需要平移变换，所以只需要3乘3），将法线乘以这个旋转矩阵即可得到世界空间下的法线。
                //既然是模型转世界用_Object2World,那为什么不直接写mul(_Object2World, v.normal)呢？反而用_World2Object？因为法线是方向向量，不能直接用_Object2World矩阵变换，因为_Object2World矩阵包含了平移部分，而法线不应该受到平移影响(顶点位置可以直接用_Object2World,但是法线是垂直于表面的方向向量，如果模型被非均匀缩放，用_Object2World变换法线会歪掉·)。正确的做法是使用_World2Object矩阵的逆转置矩阵来变换法线，但在Unity中，_World2Object已经是逆矩阵，所以可以直接使用它来变换法线。
                //mul()是一个矩阵乘法函数，接受一个向量和一个矩阵作为参数，返回矩阵与向量的乘积。这里的用法是将顶点的法线向量（v.normal）乘以_World2Object矩阵的旋转部分，以得到世界空间下的法线向量。mul(向量，矩阵)，向量在左，矩阵在右就是向量左乘矩阵，此时向量以行向量形式参与运算，mul()最终输出一个三维向量
                //normalize()函数用于将向量归一化，即将其长度调整为1，保持方向不变。这样可以确保后续的光照计算中使用的法线是单位向量，避免因长度不为1而导致的光照计算错误。
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);//获取主光源方向（世界空间）。_WorldSpaceLightPos0是Unity内置的一个变量，表示主光源在世界空间中的位置或方向。对于定向光（Directional Light），这个变量的xyz分量表示光线的反方向（即从光源指向场景的方向），w分量为0。对于点光源（Point Light）和聚光灯（Spot Light），xyz分量表示光源的位置，w分量为1。在这里，我们使用normalize()函数将主光源的方向向量归一化，以确保它是一个单位向量，这对于后续的光照计算非常重要。
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));//计算漫反射分量（主光颜色 * 材质漫反射颜色 * 法线与光线的夹角余弦）
                //这行代码是兰伯特漫反射光照模型的核心计算，最终得到的diffuse变量是该顶点处漫反射光照的最终RGB颜色值。_LightColor0.rgb：内置的全局变量，主光源的颜色与强度（颜色比例决定色相，数值大小决定强度），_Diffuse.rgb：材质的漫反射颜色（在Inspector中设置的颜色），saturate()函数用于将dot()函数的结果限制在0到1之间，确保当法线与光线夹角大于90度时（即dot()为负值）不会产生负的漫反射贡献。dot()是HLSL内置的向量点积函数。
                o.color = ambient + diffuse;//最终颜色 = 环境光 + 漫反射，o.color 存储了顶点的最终颜色值RGB类型是fixed3，将在片元着色器中进行插值后使用。
                return o;
            }

    }


    }
   

}