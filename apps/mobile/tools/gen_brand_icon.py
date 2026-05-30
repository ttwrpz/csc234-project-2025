"""Render the MoodBloom brand mark (the 5-petal flower used in the
sidebar / sign-in `MbBrandSvg`) to the two flutter_launcher_icons source
PNGs. Run from apps/mobile:  python tool/gen_brand_icon.py

Geometry mirrors `packages/design_system/lib/src/widgets/mb_svg.dart`
(_BrandPainter, 24x24 viewBox):
  * 5 petals: ellipse centred at (12,6), rx=3, ry=4.5, rotated i*72 deg
    about the centre (12,12). Fill = seed green @ 0.95.
  * inner disc: circle (12,12) r=2.4, surfaceCream.
  * core dot: circle (12,12) r=1.2, seed green @ 0.7.
"""

from PIL import Image, ImageDraw

SEED = (46, 125, 91)        # #2E7D5B
CREAM = (251, 250, 246)     # #FBFAF6 surfaceCream
ICON_BG = (255, 228, 209)   # #FFE4D1 cream-peach (adaptive + web bg)

N = 1024  # source canvas size


def draw_flower(box_px: int) -> Image.Image:
    """Render the flower into a transparent box_px square layer."""
    scale = box_px / 24.0
    cx = cy = box_px / 2.0  # viewBox centre (12,12)
    layer = Image.new("RGBA", (box_px, box_px), (0, 0, 0, 0))

    # Petals: draw one upright petal on its own layer, rotate, composite.
    for i in range(5):
        petal = Image.new("RGBA", (box_px, box_px), (0, 0, 0, 0))
        pd = ImageDraw.Draw(petal)
        # Ellipse centred at viewBox (12,6) => (cx, 6*scale), rx=3, ry=4.5.
        ex, ey = cx, 6.0 * scale
        rx, ry = 3.0 * scale, 4.5 * scale
        pd.ellipse(
            [ex - rx, ey - ry, ex + rx, ey + ry],
            fill=(SEED[0], SEED[1], SEED[2], 242),  # 0.95 alpha
        )
        petal = petal.rotate(
            -i * 72.0, resample=Image.BICUBIC, center=(cx, cy)
        )
        layer = Image.alpha_composite(layer, petal)

    d = ImageDraw.Draw(layer)
    # Inner disc (cream).
    r = 2.4 * scale
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(*CREAM, 255))
    # Core dot (seed @ 0.7).
    r = 1.2 * scale
    d.ellipse(
        [cx - r, cy - r, cx + r, cy + r],
        fill=(SEED[0], SEED[1], SEED[2], 179),
    )
    return layer


def main() -> None:
    # Full app icon: cream-peach background, flower at ~72% of the canvas.
    base = Image.new("RGBA", (N, N), (*ICON_BG, 255))
    box = int(N * 0.72)
    flower = draw_flower(box)
    off = (N - box) // 2
    base.alpha_composite(flower, (off, off))
    base.convert("RGB").save("assets/icon/app_icon.png")

    # Adaptive foreground: transparent, flower at ~60% (Android safe zone).
    fg = Image.new("RGBA", (N, N), (0, 0, 0, 0))
    box = int(N * 0.60)
    flower = draw_flower(box)
    off = (N - box) // 2
    fg.alpha_composite(flower, (off, off))
    fg.save("assets/icon/app_icon_foreground.png")

    print("wrote app_icon.png + app_icon_foreground.png")


if __name__ == "__main__":
    main()
