# 📸 Unity Shader 作品集 · 截图 & GIF 操作指南

> 所有素材输出到 `PPT素材/` 目录下，按编号对应 PPT 中的位置。

---

## ⚡ 准备工作

1. **打开 Unity Hub** → 打开本项目 `unityshader_stu1_Lambert`
2. 确保 Console 窗口无报错（红色 Error）
3. Game 视图分辨率设为 **1920×1080**（或 1280×720）
4. 截图工具推荐：
   - Windows：`Win + Shift + S`（自带截图）
   - 或：Snipaste / ShareX（可加红框标注）

---

## 一、📷 「学习照片」—— 项目结构截图

### 截图 1-A：Unity Editor 项目结构

| 步骤 | 操作 |
|------|------|
| 1 | Unity 中，左侧 **Project 窗口** 展开 `Assets/` |
| 2 | 依次展开 `漫反射光照模型/scene1~3` 和 `高光反射光照效果/scene1` |
| 3 | 右侧 **Hierarchy** 确保能看到模型（Capsule）+ Directional Light |
| 4 | 可以用 `all.unity` 场景（3 个模型并排，结构最丰富） |

**截取范围**：Project 窗口 + Hierarchy 窗口（一个屏幕内）

**PPT 配文建议**：
> 按章节分场景管理，每个实验对应独立 Shader + Material

---

### 截图 1-B（可选加分项）：带注释的 Shader 文件

| 步骤 | 操作 |
|------|------|
| 1 | 用 VS Code / Cursor 打开 `Assets/漫反射光照模型/scene1/Chapter6_DiffuseVertexLevel.shader` |
| 2 | 只展示 **Properties 块**（第 6-16 行）+ **一行 Lambert 公式**（第 51 行） |
| 3 | 截图时把注释（中文解释）露出来，体现「学习 + 写理解」的习惯 |

**PPT 配文建议**：
> 每个 Shader 附中文注释，逐行理解光照模型原理

---

## 二、📝 「代码截图」—— 核心代码块

> ⚠️ 已为你准备好 4 个代码片段文件，位于：
> `PPT素材/code_snippets/`
>
> 直接在 VS Code 中打开这些 `.txt` 文件，调整窗口只显示 15~20 行，截图即可。

### 四个代码片段文件对照表

| 编号 | 文件 | 对应 Shader | PPT 旁注 |
|------|------|-------------|----------|
| ① | `01_Lambert_VertexLevel.txt` | Chapter6_DiffuseVertexLevel.shader | 光照在顶点计算，片元仅插值 |
| ② | `02_Lambert_PixelLevel.txt` | Chapter6_DiffusePixelLevel.shader | 同模型，计算移到片元，过渡更平滑 |
| ③ | `03_HalfLambert.txt` | Chapter6_HalfLambert.shader | 背光面不再全黑，过渡更柔 |
| ④ | `04_Phong_SpecularVertex.txt` | Chapter6_SpecularVertexLevel.shader | Phong 模型：R·V 控制高光形状 |

### 截图操作（每个案例）

| 步骤 | 操作 |
|------|------|
| 1 | VS Code 打开 `PPT素材/code_snippets/0X_xxx.txt` |
| 2 | 调整窗口大小，只显示代码（收起侧边栏 `Ctrl+B`） |
| 3 | 用截图工具红框/高亮标出 `★ 核心` 标记的那一行 |
| 4 | 截图保存为 `PPT素材/code_snippets/0X_xxx_screenshot.png` |

**加分写法（可选一小框）**：
> 调试记录：修正 Pass/CGPROGRAM 嵌套、法线矩阵 `(float3x3)`、变量 `_LightColor0` 命名等编译问题。

---

## 三、🎨 「效果图」—— Game 视图对比截图

### 图 A · 逐顶点 vs 逐像素对比 ⭐（最有 TA 价值）

| 步骤 | 操作 |
|------|------|
| 1 | 打开场景 `Assets/漫反射光照模型/Scenes/all.unity` |
| 2 | 这个场景有 3 个 Capsule 并排，已分别绑定了逐顶点/逐像素/Half Lambert 材质 |
| 3 | **Game 视图** 中，调整摄像机角度使 3 个模型均可见 |
| 4 | 截图保存为 `PPT素材/effect_compare_vertex_vs_pixel.png` |

如果 all.unity 中材质未正确分配：
- 打开 `1.unity` 截图（逐顶点），再打开 `2.unity` 截图（逐像素）
- 用 PPT 或画图工具将两张图**左右并排**

**PPT 配文**：
> 同一 Lambert 模型：左逐顶点（色块感）| 右逐像素（过渡平滑）

---

### 图 B · Half Lambert vs 标准 Lambert（背光面对比）

| 步骤 | 操作 |
|------|------|
| 1 | 打开场景 `Assets/漫反射光照模型/Scenes/all.unity` |
| 2 | **关键**：在 Scene 视图中旋转 Directional Light，使光从模型背后打来 |
| 3 | 或者旋转摄像机到能看到模型背光面的角度 |
| 4 | 标准 Lambert 背光面 = 全黑；Half Lambert 背光面 = 有亮度保留 |
| 5 | 截图保存为 `PPT素材/effect_compare_halflambert.png` |

**PPT 配文**：
> Half Lambert：背光面保留一定亮度（Valve 风格常用）

---

### 图 C · Phong 高光（_Gloss 对比）

| 步骤 | 操作 |
|------|------|
| 1 | 打开场景 `Assets/高光反射光照效果/Scenes/1.unity` |
| 2 | 在 Hierarchy 选中 Capsule，在 Inspector 中找到 **SpecularVertexLevel** 材质 |
| 3 | 调整 `_Gloss` 参数为 **8**（低），截图一张 |
| 4 | 调整 `_Gloss` 参数为 **128**（高），再截图一张 |
| 5 | 两张图左右并排，保存为 `PPT素材/effect_phong_gloss_compare.png` |

**PPT 配文**：
> Phong 逐顶点高光；_Gloss 控制高光集中程度

---

## 四、🎬 GIF 制作 —— 动态光照验证

### GIF 方案选择（做 1~2 个即可，推荐 A+B）

| GIF | 时长 | 说明 |
|-----|------|------|
| **A. 旋转平行光** ⭐ | 3~5 秒 | 展示 Lambert / 高光随角度变化 |
| B. Gloss 滑条 | 2~3 秒 | 展示 Phong 指数含义 |
| C. Vertex vs Pixel | 3 秒 | 两个 Game 窗口并排，最有技术含量 |

---

### GIF A：旋转平行光（推荐首选）

| 步骤 | 操作 |
|------|------|
| 1 | 打开场景 `Assets/高光反射光照效果/Scenes/1.unity`（高光最明显） |
| 2 | Hierarchy 中选中 **Directional Light** |
| 3 | 菜单 `Window → Animation → Animation`，点击 `Create` 创建动画 |
| 4 | 在 Animation 窗口中，第 0 帧：设置 Rotation Y = 0 |
| 5 | 第 300 帧（约 10 秒 @ 30fps）：设置 Rotation Y = 360 |
| 6 | 用 **Unity Recorder** 录制（推荐）：<br>　`Window → General → Recorder → Movie`<br>　Format: MP4, Resolution: 1280×720, Frame Rate: 15<br>　录制 3~5 秒即可（0~150 帧） |
| 7 | 导出 MP4 → 上传到 [ezgif.com](https://ezgif.com/video-to-gif) 转 GIF |
| 8 | 帧率设 10~15fps，文件控制在 **3MB 以内** |
| 9 | 保存为 `PPT素材/gif_light_rotation.gif` |

**PPT 配文**：
> 实时光照变化验证；非预烘焙，Shader 实时计算

---

### GIF B：Gloss 滑条拖动

| 步骤 | 操作 |
|------|------|
| 1 | Play 模式运行场景 `高光反射光照效果/Scenes/1.unity` |
| 2 | Hierarchy 选中 Capsule，Inspector 中可见 `_Gloss` 滑条 |
| 3 | 用 OBS 或 Win+G 录屏，拖动 `_Gloss` 从 8→256 |
| 4 | 时长 2~3 秒即可 |
| 5 | 同样上传 ezgif.com 转 GIF |
| 6 | 保存为 `PPT素材/gif_gloss_slider.gif` |

**PPT 配文**：
> _Gloss 指数越大，高光越集中、光斑越小

---

### GIF C：Vertex vs Pixel 并排对比（加分项）

| 步骤 | 操作 |
|------|------|
| 1 | 同时打开两个 Game 窗口（`Window → General → Game` 新建一个） |
| 2 | 一个设 `1.unity`（逐顶点），一个设 `2.unity`（逐像素） |
| 3 | 用 OBS 同时录制两个窗口，旋转平行光 |
| 4 | 转 GIF，保存为 `PPT素材/gif_vertex_vs_pixel.gif` |

---

## 五、📦 素材整理清单

完成后，你的 `PPT素材/` 目录应包含：

```
PPT素材/
├── 截图GIF操作指南.md          ← 本指南
├── code_snippets/               ← 代码片段（已准备好）
│   ├── 01_Lambert_VertexLevel.txt
│   ├── 02_Lambert_PixelLevel.txt
│   ├── 03_HalfLambert.txt
│   └── 04_Phong_SpecularVertex.txt
│
├── 01_project_structure.png     ← 图1-A：Project + Hierarchy 结构
├── 02_shader_comment.png        ← 图1-B（可选）：带注释的 Shader
│
├── code_01_lambert_vertex.png   ← 代码① 截图
├── code_02_lambert_pixel.png    ← 代码② 截图
├── code_03_halflambert.png      ← 代码③ 截图
├── code_04_phong_specular.png   ← 代码④ 截图
│
├── effect_A_vertex_vs_pixel.png ← 图A：逐顶点 vs 逐像素
├── effect_B_halflambert.png     ← 图B：Half Lambert 背光面
├── effect_C_phong_gloss.png     ← 图C：Phong Gloss 高/低对比
│
├── gif_light_rotation.gif       ← GIF A：旋转平行光 ⭐
└── gif_gloss_slider.gif         ← GIF B：Gloss 滑条
```

---

## 🔧 附：Unity Recorder 安装与使用

1. `Window → Package Manager`
2. 左上角切换为 `Unity Registry`
3. 搜索 **Unity Recorder**，点击 `Install`
4. 安装后：`Window → General → Recorder → Recorder Window`
5. 点击 `+ Add Recorder` → 选 **Movie**
6. 设置：
   - **Format**: MP4 (H.264)
   - **Resolution**: 1280×720
   - **Frame Rate**: 15
   - **Output File**: 指定到 `PPT素材/` 目录
7. 点击红色录制按钮 → 在 Unity 中操作 → 再次点击停止

> MP4 → GIF 转换：[ezgif.com/video-to-gif](https://ezgif.com/video-to-gif)
> 参数：FPS 10~15，尺寸 720p，文件 < 3MB

---

*最后更新：2026-06-16*
