#!/usr/bin/env python3
# ============================================================
#  make_icon.py —— 程序化生成 AppIcon.icns
#
#  设计:深色 squircle 底 + 四根上升的火焰色柱条 + 顶点火苗
#  含义 = "token 消耗在涨"。无素材依赖,PIL 直出 iconset,
#  再由 iconutil 打成 .icns。
#
#  用法: python3 scripts/make_icon.py
# ============================================================
import math
import subprocess
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter

ROOT = Path(__file__).resolve().parent.parent
ICONSET = ROOT / "Resources" / "AppIcon.iconset"
OUT = ROOT / "Resources" / "AppIcon.icns"

S = 1024          # 基准分辨率
MARGIN = 88       # macOS 图标安全边距 ≈ 8.6%
RADIUS = 232      # squircle 近似圆角 ≈ 22.6%

# 配色:深夜蓝紫底,火焰橙红条
BG_TOP = (38, 34, 68)
BG_BOTTOM = (16, 14, 32)
BAR_LO = (255, 176, 66)    # 低柱:暖黄
BAR_HI = (255, 84, 54)     # 高柱:炽红


def lerp(c1, c2, t):
    return tuple(round(a + (b - a) * t) for a, b in zip(c1, c2))


def squircle_mask(size=S):
    m = Image.new("L", (size, size), 0)
    ImageDraw.Draw(m).rounded_rectangle(
        [0, 0, size - 1, size - 1], radius=RADIUS, fill=255
    )
    return m


def background():
    """纵向渐变底,裁进 squircle。"""
    img = Image.new("RGBA", (S, S))
    px = img.load()
    for y in range(S):
        c = lerp(BG_TOP, BG_BOTTOM, y / S)
        for x in range(S):
            px[x, y] = (*c, 255)
    img.putalpha(squircle_mask())
    # 顶部细高光,一点点立体感
    gloss = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    ImageDraw.Draw(gloss).rounded_rectangle(
        [0, 0, S - 1, S * 0.52], radius=RADIUS, fill=(255, 255, 255, 14)
    )
    gloss.putalpha(Image.composite(gloss.getchannel("A"), Image.new("L", (S, S), 0), squircle_mask()))
    return Image.alpha_composite(img, gloss)


def bars(img):
    """四根上升柱条,颜色由暖黄过渡到炽红,最高柱顶端落一颗火苗点。"""
    d = ImageDraw.Draw(img)
    area = S - 2 * MARGIN
    gap = area * 0.09
    w = (area - 3 * gap) / 4
    heights = [0.34, 0.52, 0.72, 0.96]     # 相对可用高度的柱高
    baseline = S - MARGIN - 40             # 统一底边
    for i, h in enumerate(heights):
        x0 = MARGIN + i * (w + gap)
        y0 = baseline - area * h
        col = lerp(BAR_LO, BAR_HI, i / 3)
        d.rounded_rectangle([x0, y0, x0 + w, baseline], radius=w * 0.28, fill=col)
        if i == 3:  # 火苗:最高柱上方的小圆,钳位保证不越出图标
            r = w * 0.34
            cx, cy = x0 + w / 2, max(y0 - r - 18, r + 28)
            d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 210, 90))
    return img


def emit_iconset(img):
    ICONSET.mkdir(parents=True, exist_ok=True)
    specs = [("16x16", 16, 1), ("16x16", 16, 2), ("32x32", 32, 1), ("32x32", 32, 2),
             ("128x128", 128, 1), ("128x128", 128, 2), ("256x256", 256, 1),
             ("256x256", 256, 2), ("512x512", 512, 1), ("512x512", 512, 2)]
    for name, base, scale in specs:
        side = base * scale
        suffix = "@2x" if scale == 2 else ""
        img.resize((side, side), Image.LANCZOS).save(ICONSET / f"icon_{name}{suffix}.png")


def main():
    img = bars(background())
    img.save(ROOT / "Resources" / "AppIcon-preview.png")
    emit_iconset(img)
    subprocess.run(["iconutil", "-c", "icns", str(ICONSET), "-o", str(OUT)], check=True)
    print(f"生成 {OUT}")


if __name__ == "__main__":
    sys.exit(main())
