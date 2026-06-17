Shader "Unity Shaders Book/Chapter6/BlinnPhong"
{
    Properties
    {
        _Diffuse ("Diffuse", Color) = (1, 1, 1, 1)
        _Specular ("Specular", Color) = (1, 1, 1, 1)
        _Gloss ("Gloss", Range(8.0, 256)) = 20
    }
    
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
                float3 worldNormal : TEXCOORD0;//世界空间法线
                float3 worldPos : TEXCOORD1;//变量存储顶点在世界空间下的三维坐标 worldPos是变量名可以自己命名。TEXCOORD1是语义是HLSL/Cg语言和GPU之间的硬性规定不能随意命名，TEXCOORD0~TEXCOORDn是一组通用的插值通道，专门用来传递自定义数据（纹理坐标、世界位置、世界法线等都可以存）
            };
            v2f vert(a2v v)
            {
                v2f o;
                o.pos = UnityObjectToClipPos(v.vertex);//顶点位置转裁剪空间，裁剪空间下的顶点坐标存入o.pos  v.vertex顶点在模型空间的原始坐标（建模软件里定义的本地坐标）
                o.worldNormal = mul(v.normal,(float3x3)unity_WorldToObject);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }
            fixed4 frag(v2f i) : SV_Target//片元着色器，输入为顶点着色器传递的结构体v2f，输出为一个四分量颜色（RGBA），使用SV_Target语义表示这是渲染目标的输出。
            {
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;//把unity内置的环境光颜色取出并赋给变量ambient。  UNITY_LIGHTMODEL_AMBIENT 是 Unity 的内置 uniform（通常是一个四分量颜色 float4），表示场景的环境光（Ambient）颜色／强度。.xyz 只取其 RGB 。 ambient变量是一个表示环境光的RGB值的一个三分量向量。

                fixed3 worldNormal = normalize(i.worldNormal);//取世界空间法线的单位向量（归一化）
                fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);//对世界空间下的主光照方向向量进行归一化

                fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb * saturate(dot(worldNormal,worldLightDir));//这句代码是标准兰伯特漫反射光照模型的逐像素实现。漫反射结果 = 入射光颜色 x 材质漫反射固有色 x 兰伯特余弦因子

                fixed3 reflectDir = normalize(reflect(-worldLightDir, worldNormal));//reflect()反射函数要求输入的是入射光方向（也就是从光源射向像素表面，但worldLightDir是从像素指向光源的方向所以要加负号），reflect(入射方向，法线)是内置函数，输出是光线撞到表面后，镜面反射出去的光线方向向量。
                //reflectDir最终得到一个三维单位向量，代表当前像素表面的理性镜面反射光方向。
                fixed3 viewDir = normalize(_WorldSpaceCameraPos.xyz - i.worldPos.xyz);//viewDir是当前像素指向摄像机（观察者）的单位方向向量
                
                fixed3 halfDir = normalize(worldLightDir + viewDir);//得到就是两个方向的角平分线方向，叫做半角向量。

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(max(0,dot(worldNormal,halfDir)), _Gloss);//Blinn模型计算高光反射的公式
                
                return fixed4(ambient + diffuse + specular, 1.0);//最终输出的是当前这一个像素最终显示在屏幕上的RGBA颜色（由环境光、漫反射、高光三种光照分量叠加而成），1.0代表完全不透明。

            }
            ENDCG
        }
    }
    Fallback "Specular"
}
