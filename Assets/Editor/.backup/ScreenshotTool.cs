using UnityEngine;
using UnityEditor;
using UnityEditor.SceneManagement;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System;

/// <summary>
/// PPT 素材自动截图工具
/// GUI 模式: Tools → PPT Screenshot Tool
/// 批处理模式: Unity.exe -batchmode -projectPath ... -executeMethod ScreenshotTool.BatchCaptureAll -quit
/// </summary>
public class ScreenshotTool : EditorWindow
{
    const string OUTPUT_DIR = "Screenshots";
    const string GIF_FRAMES_DIR_A = "Screenshots/gif_frames_rotation";
    const string GIF_FRAMES_DIR_B = "Screenshots/gif_frames_gloss";

    // 协程队列 (EditorWindow 不支持 StartCoroutine，用 EditorApplication.update 模拟)
    static Queue<Action> _pendingActions = new Queue<Action>();
    static IEnumerator _currentRoutine;
    static bool _updateHooked;

    [MenuItem("Tools/PPT Screenshot Tool")]
    static void ShowWindow()
    {
        var window = GetWindow<ScreenshotTool>("PPT Screenshot Tool");
        window.minSize = new Vector2(400, 600);
    }

    void OnGUI()
    {
        GUILayout.Label("PPT 素材自动截图工具", EditorStyles.boldLabel);
        GUILayout.Space(10);

        EditorGUILayout.HelpBox(
            "Game 视图建议 1920x1080\n命令行: -executeMethod ScreenshotTool.BatchCaptureAll",
            MessageType.Info);

        GUILayout.Space(10);

        GUILayout.Label("一、效果对比截图", EditorStyles.boldLabel);

        if (GUILayout.Button("★ 全部截图 (图A+B+C)", GUILayout.Height(40)))
            RunCoroutine(DoAllCaptures());

        if (GUILayout.Button("图A: 逐顶点 vs 逐像素对比", GUILayout.Height(30)))
            RunCoroutine(DoCaptureA());

        if (GUILayout.Button("图B: Half Lambert 背光面", GUILayout.Height(30)))
            RunCoroutine(DoCaptureB());

        if (GUILayout.Button("图C: Phong Gloss=8", GUILayout.Height(30)))
            RunCoroutine(DoCaptureC(8));

        if (GUILayout.Button("图C: Phong Gloss=128", GUILayout.Height(30)))
            RunCoroutine(DoCaptureC(128));

        GUILayout.Space(10);

        GUILayout.Label("二、GIF 帧录制", EditorStyles.boldLabel);

        if (GUILayout.Button("GIF A: 旋转平行光 360° (60帧)", GUILayout.Height(30)))
            RunCoroutine(DoRecordGifA(60, 360f));

        if (GUILayout.Button("GIF B: Gloss 8→256 (30帧)", GUILayout.Height(30)))
            RunCoroutine(DoRecordGifB(30));

        GUILayout.Space(10);

        string fullOutput = Path.GetFullPath(Path.Combine(Application.dataPath, "..", OUTPUT_DIR));
        EditorGUILayout.SelectableLabel($"输出: {fullOutput}");

        if (GUILayout.Button("打开输出文件夹"))
            EditorUtility.RevealInFinder(fullOutput);
    }

    // ── 简易协程系统 ──

    static void RunCoroutine(IEnumerator routine)
    {
        _currentRoutine = routine;
        if (!_updateHooked)
        {
            _updateHooked = true;
            EditorApplication.update += UpdateCoroutine;
        }
    }

    static void UpdateCoroutine()
    {
        try
        {
            if (_currentRoutine != null && !_currentRoutine.MoveNext())
            {
                _currentRoutine = null;
                if (_pendingActions.Count == 0)
                {
                    _updateHooked = false;
                    EditorApplication.update -= UpdateCoroutine;
                }
            }
            // 处理队列中的延迟操作
            while (_pendingActions.Count > 0)
            {
                _pendingActions.Dequeue()?.Invoke();
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"Coroutine error: {e}");
            _currentRoutine = null;
            _updateHooked = false;
            EditorApplication.update -= UpdateCoroutine;
        }
    }

    // ── 协程逻辑 ──

    static IEnumerator DoAllCaptures()
    {
        yield return DoCaptureA();
        yield return DoCaptureB();
        yield return DoCaptureC(8);
        yield return DoCaptureC(128);
        Debug.Log("<color=green>===== 全部截图完成! =====</color>");
    }

    static IEnumerator DoCaptureA()
    {
        Debug.Log("[图A] 逐顶点 vs 逐像素...");
        EditorSceneManager.OpenScene("Assets/漫反射光照模型/Scenes/all.unity");
        yield return null; yield return null; yield return null;
        AdjustCameraStatic(new Vector3(0, 2, -8), Vector3.zero);
        yield return null;
        CaptureScreenStatic("effect_A_vertex_vs_pixel.png");
    }

    static IEnumerator DoCaptureB()
    {
        Debug.Log("[图B] Half Lambert 背光面...");
        EditorSceneManager.OpenScene("Assets/漫反射光照模型/Scenes/all.unity");
        yield return null; yield return null; yield return null;
        RotateLightStatic(new Vector3(50, -30, 0));
        AdjustCameraStatic(new Vector3(3, 1.5f, 6), new Vector3(0, 1, 0));
        yield return null;
        CaptureScreenStatic("effect_B_halflambert_backlight.png");
    }

    static IEnumerator DoCaptureC(float gloss)
    {
        Debug.Log($"[图C] Phong Gloss={gloss}...");
        EditorSceneManager.OpenScene("Assets/高光反射光照效果/Scenes/1.unity");
        yield return null; yield return null; yield return null;
        SetMaterialGlossStatic(gloss);
        RotateLightStatic(new Vector3(50, 30, 0));
        AdjustCameraStatic(new Vector3(2, 2, -5), new Vector3(0, 0.5f, 0));
        yield return null;
        CaptureScreenStatic($"effect_C_phong_gloss_{gloss}.png");
    }

    static IEnumerator DoRecordGifA(int frameCount, float totalAngle)
    {
        Debug.Log("[GIF A] 旋转平行光...");
        EditorSceneManager.OpenScene("Assets/高光反射光照效果/Scenes/1.unity");
        yield return null; yield return null; yield return null;

        string frameDir = EnsureGifFramesDirStatic(GIF_FRAMES_DIR_A);
        Light light = UnityEngine.Object.FindObjectOfType<Light>();
        if (light == null) { Debug.LogError("No light!"); yield break; }

        SetMaterialGlossStatic(64);
        float anglePerFrame = totalAngle / frameCount;
        Vector3 baseRotation = light.transform.eulerAngles;

        for (int i = 0; i < frameCount; i++)
        {
            light.transform.eulerAngles = new Vector3(
                baseRotation.x, baseRotation.y + anglePerFrame * i, baseRotation.z);
            yield return null;
            string path = Path.Combine(frameDir, $"frame_{i:D04}.png");
            ScreenCapture.CaptureScreenshot(path, 1);
            if (i % 10 == 0) Debug.Log($"  Frame {i + 1}/{frameCount}");
        }
        Debug.Log($"<color=green>[OK]</color> {frameCount} frames → {frameDir}");
    }

    static IEnumerator DoRecordGifB(int frameCount)
    {
        Debug.Log("[GIF B] Gloss 滑条变化...");
        EditorSceneManager.OpenScene("Assets/高光反射光照效果/Scenes/1.unity");
        yield return null; yield return null; yield return null;

        string frameDir = EnsureGifFramesDirStatic(GIF_FRAMES_DIR_B);
        RotateLightStatic(new Vector3(50, 30, 0));

        for (int i = 0; i < frameCount; i++)
        {
            float gloss = Mathf.Lerp(8f, 256f, (float)i / (frameCount - 1));
            SetMaterialGlossStatic(gloss);
            yield return null;
            string path = Path.Combine(frameDir, $"frame_{i:D04}.png");
            ScreenCapture.CaptureScreenshot(path, 1);
            if (i % 5 == 0) Debug.Log($"  Gloss={gloss:F0}, Frame {i + 1}/{frameCount}");
        }
        Debug.Log($"<color=green>[OK]</color> {frameCount} frames → {frameDir}");
    }

    // ==================== 批处理模式 (batch mode) ====================
    // 使用 EditorApplication.update 回调链，每步让 Unity 渲染一帧

    static int _batchStep;
    static int _batchFrameIndex;
    static int _batchTotalFrames;
    static string _batchFrameDir;
    static string _batchGifType;
    static Light _batchLight;
    static float _batchLightAnglePerFrame;
    static Vector3 _batchLightBaseRot;

    static void BatchCaptureAll()
    {
        Debug.Log("[ScreenshotTool] Batch: starting capture sequence...");
        _batchStep = 0;
        _batchFrameIndex = 0;
        EditorApplication.update += BatchUpdateCaptureAll;
    }

    static void BatchUpdateCaptureAll()
    {
        try
        {
            switch (_batchStep)
            {
                case 0: // 初始化
                    _batchStep = 1;
                    break;
                case 1: // 打开场景 all.unity
                    EditorSceneManager.OpenScene("Assets/漫反射光照模型/Scenes/all.unity");
                    _batchStep = 2;
                    break;
                case 2: case 3: case 4: case 5: // 等待场景加载 + 几帧渲染
                    _batchStep++;
                    break;
                case 6: // 图A: 正面摄像机
                    AdjustCameraStatic(new Vector3(0, 2, -8), Vector3.zero);
                    _batchStep++;
                    break;
                case 7: case 8: // 等渲染帧
                    _batchStep++;
                    break;
                case 9:
                    CaptureScreenStatic("effect_A_vertex_vs_pixel.png");
                    _batchStep++;
                    break;
                case 10: // 图B: 旋转灯光到背光面
                    RotateLightStatic(new Vector3(50, -30, 0));
                    AdjustCameraStatic(new Vector3(3, 1.5f, 6), new Vector3(0, 1, 0));
                    _batchStep++;
                    break;
                case 11: case 12: case 13:
                    _batchStep++;
                    break;
                case 14:
                    CaptureScreenStatic("effect_B_halflambert_backlight.png");
                    _batchStep++;
                    break;
                case 15: // 打开高光场景
                    EditorSceneManager.OpenScene("Assets/高光反射光照效果/Scenes/1.unity");
                    _batchStep++;
                    break;
                case 16: case 17: case 18: case 19:
                    _batchStep++;
                    break;
                case 20: // 图C: Gloss=8
                    SetMaterialGlossStatic(8);
                    RotateLightStatic(new Vector3(50, 30, 0));
                    AdjustCameraStatic(new Vector3(2, 2, -5), new Vector3(0, 0.5f, 0));
                    _batchStep++;
                    break;
                case 21: case 22: case 23:
                    _batchStep++;
                    break;
                case 24:
                    CaptureScreenStatic("effect_C_phong_gloss_8.png");
                    _batchStep++;
                    break;
                case 25: // 图C: Gloss=128
                    SetMaterialGlossStatic(128);
                    _batchStep++;
                    break;
                case 26: case 27: case 28:
                    _batchStep++;
                    break;
                case 29:
                    CaptureScreenStatic("effect_C_phong_gloss_128.png");
                    _batchStep++;
                    break;
                case 30: // 完成!
                    Debug.Log("<color=green>[ScreenshotTool] All screenshots captured!</color>");
                    EditorApplication.update -= BatchUpdateCaptureAll;
                    EditorApplication.Exit(0);
                    break;
                default:
                    _batchStep++;
                    break;
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"Batch error at step {_batchStep}: {e}");
            EditorApplication.update -= BatchUpdateCaptureAll;
            EditorApplication.Exit(1);
        }
    }

    static void BatchRecordGifA()
    {
        Debug.Log("[ScreenshotTool] Batch: recording light rotation GIF...");
        _batchStep = 0;
        _batchFrameIndex = 0;
        _batchTotalFrames = 60;
        _batchGifType = "A";
        _batchFrameDir = EnsureGifFramesDirStatic(GIF_FRAMES_DIR_A);
        EditorApplication.update += BatchUpdateRecordGif;
    }

    static void BatchRecordGifB()
    {
        Debug.Log("[ScreenshotTool] Batch: recording gloss slider GIF...");
        _batchStep = 0;
        _batchFrameIndex = 0;
        _batchTotalFrames = 30;
        _batchGifType = "B";
        _batchFrameDir = EnsureGifFramesDirStatic(GIF_FRAMES_DIR_B);
        EditorApplication.update += BatchUpdateRecordGif;
    }

    static void BatchUpdateRecordGif()
    {
        try
        {
            switch (_batchStep)
            {
                case 0:
                    EditorSceneManager.OpenScene("Assets/高光反射光照效果/Scenes/1.unity");
                    _batchStep = 1;
                    break;
                case 1: case 2: case 3: case 4: // 等场景加载
                    _batchStep++;
                    break;
                case 5: // 初始化
                    _batchLight = UnityEngine.Object.FindObjectOfType<Light>();
                    if (_batchLight == null) { Debug.LogError("No light!"); EditorApplication.update -= BatchUpdateRecordGif; EditorApplication.Exit(1); return; }
                    SetMaterialGlossStatic(_batchGifType == "A" ? 64 : 8);
                    if (_batchGifType == "B") RotateLightStatic(new Vector3(50, 30, 0));
                    _batchLightBaseRot = _batchLight.transform.eulerAngles;
                    _batchLightAnglePerFrame = 360f / _batchTotalFrames;
                    _batchFrameIndex = 0;
                    _batchStep = 6;
                    break;
                case 6: // 逐帧录制
                    if (_batchFrameIndex < _batchTotalFrames)
                    {
                        if (_batchGifType == "A")
                        {
                            _batchLight.transform.eulerAngles = new Vector3(
                                _batchLightBaseRot.x, _batchLightBaseRot.y + _batchLightAnglePerFrame * _batchFrameIndex, _batchLightBaseRot.z);
                        }
                        else
                        {
                            SetMaterialGlossStatic(Mathf.Lerp(8f, 256f, (float)_batchFrameIndex / (_batchTotalFrames - 1)));
                        }
                        // 等待一帧渲染后再截图
                        _batchStep = 7;
                    }
                    else
                    {
                        _batchStep = 8;
                    }
                    break;
                case 7: // 截图当前帧
                    {
                        string path = Path.Combine(_batchFrameDir, $"frame_{_batchFrameIndex:D04}.png");
                        ScreenCapture.CaptureScreenshot(path, 1);
                        if (_batchFrameIndex % 10 == 0 || _batchFrameIndex % 5 == 0)
                            Debug.Log($"Frame {_batchFrameIndex + 1}/{_batchTotalFrames}");
                        _batchFrameIndex++;
                        _batchStep = 6; // 回退继续下一帧
                    }
                    break;
                case 8: // 完成
                    Debug.Log($"<color=green>[OK] GIF {_batchGifType}: {_batchTotalFrames} frames → {_batchFrameDir}</color>");
                    EditorApplication.update -= BatchUpdateRecordGif;
                    EditorApplication.Exit(0);
                    break;
            }
        }
        catch (Exception e)
        {
            Debug.LogError($"GIF record error at step {_batchStep}: {e}");
            EditorApplication.update -= BatchUpdateRecordGif;
            EditorApplication.Exit(1);
        }
    }

    // ==================== 静态辅助方法 ====================

    static string EnsureOutputDirStatic()
    {
        string dir = Path.GetFullPath(Path.Combine(Application.dataPath, "..", OUTPUT_DIR));
        Directory.CreateDirectory(dir);
        return dir;
    }

    static string EnsureGifFramesDirStatic(string subDir)
    {
        string dir = Path.GetFullPath(Path.Combine(Application.dataPath, "..", subDir));
        if (Directory.Exists(dir))
        {
            foreach (string f in Directory.GetFiles(dir)) File.Delete(f);
        }
        Directory.CreateDirectory(dir);
        return dir;
    }

    static void CaptureScreenStatic(string filename)
    {
        string path = Path.Combine(EnsureOutputDirStatic(), filename);
        ScreenCapture.CaptureScreenshot(path, 1);
        Debug.Log($"[OK] Screenshot: {path}");
    }

    static void AdjustCameraStatic(Vector3 pos, Vector3 lookAt)
    {
        Camera cam = Camera.main;
        if (cam != null) { cam.transform.position = pos; cam.transform.LookAt(lookAt); }
        else Debug.LogWarning("No Main Camera found in scene!");
    }

    static void RotateLightStatic(Vector3 euler)
    {
        Light light = UnityEngine.Object.FindObjectOfType<Light>();
        if (light != null) light.transform.eulerAngles = euler;
        else Debug.LogWarning("No Directional Light found!");
    }

    static void SetMaterialGlossStatic(float gloss)
    {
        string[] guids = AssetDatabase.FindAssets("SpecularVertexLevel t:Material");
        if (guids.Length > 0)
        {
            Material mat = AssetDatabase.LoadAssetAtPath<Material>(
                AssetDatabase.GUIDToAssetPath(guids[0]));
            if (mat != null) mat.SetFloat("_Gloss", gloss);
        }
        else Debug.LogWarning("SpecularVertexLevel material not found!");
    }
}
