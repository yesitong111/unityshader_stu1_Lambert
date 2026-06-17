"""生成代码截图 PNG，带语法高亮 + 核心行标注"""
import os
from pygments import highlight
from pygments.lexers.graphics import HLSLShaderLexer
from pygments.formatters import ImageFormatter
from pygments.styles import get_style_by_name

OUT_DIR = r"G:\GitHub_myproject\unityshader_stu1_Lambert\PPT素材\code_snippets"

# ── 四个代码片段 ──────────────────────────────────────────
snippets = {
    "01_Lambert_VertexLevel.png": {
        "title": "// Lambert 逐顶点 — Chapter6_DiffuseVertexLevel.shader",
        "code": """v2f vert(a2v v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);

    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
    fixed3 worldNormal = normalize(mul(v.normal,
                              (float3x3)unity_WorldToObject));
    fixed3 worldLight  = normalize(_WorldSpaceLightPos0.xyz);

    // 核心：Lambert 漫反射 = N·L，saturate 钳制负值
    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb
                   * saturate(dot(worldNormal, worldLight));

    o.color = ambient + diffuse;     // 顶点级完成光照计算
    return o;
}

fixed4 frag(v2f i) : SV_Target
{
    return fixed4(i.color, 1.0);     // 片元仅插值，无额外计算
}""",
        "hl_lines": [11, 12],  # 核心行
        "caption": "光照在顶点计算，片元仅插值",
    },
    "02_Lambert_PixelLevel.png": {
        "title": "// Lambert 逐像素 — Chapter6_DiffusePixelLevel.shader",
        "code": """v2f vert(a2v v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);
    o.worldNormal = mul(v.normal,
                    (float3x3)unity_WorldToObject);
    return o;                        // 顶点只传法线，不计算光照
}

fixed4 frag(v2f i) : SV_Target
{
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
    fixed3 worldNormal  = normalize(i.worldNormal);
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

    // 核心：saturate(dot(N,L)) 在片元逐像素计算
    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb
                   * saturate(dot(worldNormal, worldLightDir));

    fixed3 color = ambient + diffuse;
    return fixed4(color, 1.0);
}""",
        "hl_lines": [13, 14],
        "caption": "同模型，计算移到片元，过渡更平滑",
    },
    "03_HalfLambert.png": {
        "title": "// Half Lambert — Chapter6_HalfLambert.shader",
        "code": """fixed4 frag(v2f i) : SV_Target
{
    fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
    fixed3 worldNormal  = normalize(i.worldNormal);
    fixed3 worldLightDir = normalize(_WorldSpaceLightPos0.xyz);

    // 核心：dot*0.5+0.5 将 [-1,1] 映射到 [0,1]
    // 标准 Lambert: saturate(dot) → 背光面 = 0（全黑）
    // Half Lambert:  映射后 → 背光面仍保留一定亮度
    fixed halfLambert = dot(worldNormal, worldLightDir)
                      * 0.5 + 0.5;
    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb
                   * halfLambert;

    fixed3 color = ambient + diffuse;
    return fixed4(color, 1.0);
}""",
        "hl_lines": [8, 9],
        "caption": "背光面不再全黑，过渡更柔（Valve 风格）",
    },
    "04_Phong_SpecularVertex.png": {
        "title": "// Phong 逐顶点高光 — Chapter6_SpecularVertexLevel.shader",
        "code": """v2f vert(a2v v)
{
    v2f o;
    o.pos = UnityObjectToClipPos(v.vertex);

    fixed3 ambient  = UNITY_LIGHTMODEL_AMBIENT.xyz;
    fixed3 worldNormal = normalize(mul(v.normal,
                              (float3x3)unity_WorldToObject));
    fixed3 worldLight  = normalize(_WorldSpaceLightPos0.xyz);

    // 漫反射（Lambert）
    fixed3 diffuse = _LightColor0.rgb * _Diffuse.rgb
                   * saturate(dot(worldNormal, worldLight));

    // 核心：Phong 高光 — reflect + pow(dot(R,V), _Gloss)
    fixed3 reflectDir = normalize(
                        reflect(-worldLight, worldNormal));
    fixed3 viewDir    = normalize(_WorldSpaceCameraPos.xyz
                     - mul(unity_ObjectToWorld, v.vertex).xyz);
    fixed3 specular   = _LightColor0.rgb * _Specular.rgb
                      * pow(saturate(dot(reflectDir, viewDir)),
                            _Gloss);

    o.color = ambient + diffuse + specular;
    return o;
}""",
        "hl_lines": [15, 16, 17, 18, 19],
        "caption": "Phong 模型：R·V 控制高光形状；_Gloss 控制集中程度",
    },
}


def generate_all():
    """生成所有代码截图"""
    os.makedirs(OUT_DIR, exist_ok=True)

    for filename, info in snippets.items():
        out_path = os.path.join(OUT_DIR, filename)

        # 合并标题和代码
        full_code = info["title"] + "\n" + info["code"]

        # 创建 formatter
        formatter = ImageFormatter(
            style="monokai",
            font_name="Consolas",
            font_size=15,
            line_numbers=False,
            line_pad=4,
            image_pad=20,
            hl_lines=info["hl_lines"],
            hl_color="#ff6188",  # 红色/粉色高亮（Monokai 风格）
        )

        # 生成图片
        result = highlight(full_code, HLSLShaderLexer(), formatter)

        with open(out_path, "wb") as f:
            f.write(result)

        print(f"[OK] Generated: {filename}  (highlight lines: {info['hl_lines']})")
        print(f"      Caption: {info['caption']}")
        print()

    print(f"All done! Output: {OUT_DIR}")


if __name__ == "__main__":
    generate_all()
