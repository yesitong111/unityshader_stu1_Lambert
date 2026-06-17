"""将 Unity ScreenshotTool 录制的帧序列合成 GIF"""
import os
import sys
import glob
import imageio
from PIL import Image

FRAMES_DIR = r"G:\GitHub_myproject\unityshader_stu1_Lambert\PPT素材\gif_frames"
OUT_DIR = r"G:\GitHub_myproject\unityshader_stu1_Lambert\PPT素材"


def build_gif(name, fps=12, max_size_mb=3):
    """读取帧序列，合成 GIF"""
    frames_path = os.path.join(FRAMES_DIR, "frame_*.png")
    png_files = sorted(glob.glob(frames_path))

    if not png_files:
        print(f"[ERROR] 未找到帧文件！请检查: {frames_path}")
        print("先运行 Unity → Tools → PPT Screenshot Tool 录制 GIF 帧")
        return None

    print(f"找到 {len(png_files)} 帧")

    # 读取帧并处理大小
    frames = []
    for png in png_files:
        img = Image.open(png)
        # 缩放到 720p（如果原始是 1080p）
        if img.height > 720:
            ratio = 720 / img.height
            new_size = (int(img.width * ratio), 720)
            img = img.resize(new_size, Image.LANCZOS)
        frames.append(img)

    out_path = os.path.join(OUT_DIR, name)

    # 逐步降低帧率直到文件 < max_size_mb
    target_fps = fps
    while target_fps >= 6:
        # 子采样帧
        step = max(1, int(12 / target_fps))
        sampled_frames = frames[::step]

        # 写入临时文件
        temp_path = out_path + ".tmp.gif"
        imageio.mimsave(temp_path, sampled_frames, format='GIF',
                        fps=target_fps, loop=0,
                        palettesize=128,
                        subrectangles=True)

        file_size_mb = os.path.getsize(temp_path) / (1024 * 1024)
        print(f"  fps={target_fps}, frames={len(sampled_frames)}, size={file_size_mb:.1f}MB")

        if file_size_mb <= max_size_mb:
            # 合格，保存为最终文件
            os.replace(temp_path, out_path)
            print(f"[OK] {name} 已生成 ({file_size_mb:.1f}MB, {target_fps}fps)")
            return out_path
        else:
            os.remove(temp_path)
            target_fps -= 2

    print(f"[WARN] 无法将文件压缩到 {max_size_mb}MB 以下，已尽力")
    return None


if __name__ == "__main__":
    if len(sys.argv) > 1:
        gif_name = sys.argv[1]
    else:
        gif_name = "gif_light_rotation.gif"

    print(f"合成 GIF: {gif_name}")
    build_gif(gif_name)

    # 如果帧目录还在，提示也可以做第二个 GIF
    print("")
    print("用法: python build_gif.py [输出文件名]")
    print("示例:")
    print("  python build_gif.py gif_light_rotation.gif")
    print("  python build_gif.py gif_gloss_slider.gif")
