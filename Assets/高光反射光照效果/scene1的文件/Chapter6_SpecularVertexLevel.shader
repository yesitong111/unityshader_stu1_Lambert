// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'
// Upgrade NOTE: replaced 'mul(UNITY_MATRIX_MVP,*)' with 'UnityObjectToClipPos(*)'

Shader "Unity Shaders Book/Chapter6/SpecularVertexLevel"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    /*
            定义了材质在 Inspector 中可调的属性。这里有三个属性：
            名称：_Diffuse（Shader 内部的变量名）
            显示名："Diffuse"（Inspector 中显示）
            类型：Color（颜色）
            默认值：(1,1,1,1) —— 即白色，控制漫反射颜色。
            名称：_Specular
            显示名："Specular"
            类型：Color
            默认值：(1,1,1,1) —— 控制高光反射颜色。
            名称：_Gloss
            显示名："Gloss"
            类型：Range(8.0, 256)
            默认值：20 —— 控制高光区域大小，数值越大高光越集中、范围越小。
        */
    SubShader
    {
        Pass{
            Tags { "LightMode" = "ForwardBase" }//Tag "LightMode"="ForwardBase" 表示这个 Pass 用于前向渲染的基底光照通道（处理主光源与环境光，额外光通常用 ForwardAdd）
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "Lighting.cginc"//包含 Unity 内置的光照/实用函数（GI、光照计算辅助宏等），方便实现灯光相关计算。
            fixed4 _Diffuse;//声明一个 uniform 变量，类型为四分量颜色，它应对应在 Properties 中定义的 _Diffuse（材质面板中可设置的漫反射颜色）。
            fixed4 _Specular;//声明高光反射颜色 uniform，对应 Properties 中的 _Specular。
            float _Gloss;//声明高光光泽度 uniform，对应 Properties 中的 _Gloss，用于 pow 指数控制高光范围。
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
                fixed3 color : COLOR;//顶点颜色（环境光 + 漫反射 + 高光）
            };
            v2f vert(a2v v)
            {
                v2f o;
                // 将顶点从对象空间变换到裁剪空间
                o.pos = UnityObjectToClipPos(v.vertex);
                // 计算顶点的环境光、漫反射与高光反射光照
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//获取环境光颜色RGB
                fixed3 worldNormal = normalize(mul(v.normal, (float3x3)unity_WorldToObject)); //将法线从模型空间变换到世界空间，v.normal是模型空间下的法线，_World2Object是从世界空间到对象空间的变换矩阵，取其前三行三列得到旋转部分（法线是方向向量，等价于w=0的齐次坐标不需要平移变换，所以只需要3乘3），将法线乘以这个旋转矩阵即可得到世界空间下的法线。
                //既然是模型转世界用_Object2World,那为什么不直接写mul(_Object2World, v.normal)呢？反而用_World2Object？因为法线是方向向量，不能直接用_Object2World矩阵变换，因为_Object2World矩阵包含了平移部分，而法线不应该受到平移影响(顶点位置可以直接用_Object2World,但是法线是垂直于表面的方向向量，如果模型被非均匀缩放，用_Object2World变换法线会歪掉·)。正确的做法是使用_World2Object矩阵的逆转置矩阵来变换法线，但在Unity中，_World2Object已经是逆矩阵，所以可以直接使用它来变换法线。
                //mul()是一个矩阵乘法函数，接受一个向量和一个矩阵作为参数，返回矩阵与向量的乘积。这里的用法是将顶点的法线向量（v.normal）乘以_World2Object矩阵的旋转部分，以得到世界空间下的法线向量。mul(向量，矩阵)，向量在左，矩阵在右就是向量左乘矩阵，此时向量以行向量形式参与运算，mul()最终输出一个三维向量
                //normalize()函数用于将向量归一化，即将其长度调整为1，保持方向不变。这样可以确保后续的光照计算中使用的法线是单位向量，避免因长度不为1而导致的光照计算错误。
                fixed3 worldLight = normalize(_WorldSpaceLightPos0.xyz);//获取主光源方向（世界空间）。_WorldSpaceLightPos0是Unity内置的一个变量，表示主光源在世界空间中的位置或方向。对于定向光（Directional Light），这个变量的xyz分量表示光线的反方向（即从光源指向场景的方向），w分量为0。对于点光源（Point Light）和聚光灯（Spot Light），xyz分量表示光源的位置，w分量为1。在这里，我们使用normalize()函数将主光源的方向向量归一化，以确保它是一个单位向量，这对于后续的光照计算非常重要。
                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal, worldLight));//计算漫反射分量（主光颜色 * 材质漫反射颜色 * 法线与光线的夹角余弦）
                //这行代码是兰伯特漫反射光照模型的核心计算，最终得到的diffuse变量是该顶点处漫反射光照的最终RGB颜色值。_LightColor0.rgb：内置的全局变量，主光源的颜色与强度（颜色比例决定色相，数值大小决定强度），_Diffuse.rgb：材质的漫反射颜色（在Inspector中设置的颜色），saturate()函数用于将dot()函数的结果限制在0到1之间，确保当法线与光线夹角大于90度时（即dot()为负值）不会产生负的漫反射贡献。dot()是HLSL内置的向量点积函数。
                fixed3 reflectDir = normalize(reflect(-worldLight, worldNormal));//计算反射方向。reflect()是HLSL内置函数，根据入射方向（此处取-worldLight，即从表面指向光源的反方向）和法线worldNormal，计算镜面反射方向reflectDir。normalize()将其归一化为单位向量，供后续高光计算使用。
                //float3 reflect(float3 i, float3 n);输入参数i：入射光向量，方向要求是指向物体表面。输入参数n:表面法线向量，方向是从表面指向外部（输入归一化的单位向量时结果才准确）返回值（输出）：一个三维向量，代表反射光线的方向
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - mul(unity_ObjectToWorld, v.vertex).xyz);//计算视线方向viewDir（从顶点指向摄像机）。mul(unity_ObjectToWorld, v.vertex)将顶点从对象空间变换到世界空间，_WorldSpaceCameraPos是摄像机在世界空间的位置，两者相减得到从顶点指向摄像机的向量，再normalize()归一化为单位向量。
                //viewDir表示观察者方向，把它定义为顶点->摄像机，是为了和反射光向量的起点、方向逻辑统一；只有viewDir与reflectDir越接近，高光越亮。我们判断高光亮不亮，本质是在判断：反射光的方向，和“进入眼睛的光线方向”重合度有多高。反射光的方向是由入射光和法线决定的，而进入眼睛的光线方向就是从顶点指向摄像机的viewDir。只有当viewDir和reflectDir越接近（即夹角越小，dot()值越大），高光才会越亮。
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(reflectDir, viewDir)), _Gloss);//作用是计算当前顶点/像素的镜面高光颜色与亮度；最终输出的specular是一个RGB颜色值。
                //dot(reflectDir, viewDir)计算反射方向与视线方向的夹角余弦，范围在[-1，1]两个方向越重合数值越大，代表反射光越能进入相机，高光越亮；saturate()限制在[0,1]；pow(..., _Gloss)将余弦值进行_Gloss次幂，指数越大高光区域越小、越锐利。_Gloss是材质的光泽度参数：数值越大，高光光斑越小、边缘越锐利。_Specular.rgb是材质自身的高光颜色，由我们在材质面板上调节。pow(saturate(dot(reflectDir, viewDir)), _Gloss)输出一个0~1之间的纯数字（标量），只代表高光的强弱程度。
                //最终高光颜色 = 光源颜色 x 材质高光颜色 x 高光强度系数
                o.color = ambient + diffuse + specular;//最终颜色 = 环境光 + 漫反射 + 高光反射，o.color 存储了顶点的最终颜色值，将在片元着色器中进行插值后使用。
                return o;
            }
            fixed4 frag(v2f i) : SV_Target//片元着色器，输入为顶点着色器传递的结构体v2f，输出为一个四分量颜色（RGBA），使用SV_Target语义表示这是渲染目标的输出。
            {
                return fixed4(i.color, 1.0);//片元着色器直接输出顶点传递过来的颜色值，alpha通道设置为1.0（完全不透明）。由于顶点着色器计算的颜色已经包含了环境光、漫反射和高光的贡献，所以片元着色器不需要进行额外的光照计算。
            }
            ENDCG
        }
    }
    Fallback "Specular"//指定一个后备着色器，当当前平台不支持这个自定义着色器时，Unity 将使用内置的 Specular 着色器来渲染对象。这确保了在不支持自定义着色器的环境中，物体仍然能够正确显示。
}
