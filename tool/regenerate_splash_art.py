"""Render Android 12+ splash icons with the diary logo on a
TRANSPARENT background, sized to fit fully inside the platform's
circular icon safe area.

Android 12+ clips the splash icon into a circle whose diameter is
about 2/3 of the icon canvas. Anything outside that circle gets
cropped. We size the diary to 65% of the canvas so its outer details
(spiral binding, strap, bottom bookmark) all sit comfortably inside
the safe area and the full diary is visible.

Outputs:
  - android/app/src/main/res/drawable-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/android12splash.png
  - android/app/src/main/res/drawable-night-{mdpi,hdpi,xhdpi,xxhdpi,xxxhdpi}/android12splash.png
"""

from pathlib import Path

from PIL import Image, ImageDraw

REPO_ROOT = Path(__file__).resolve().parents[1]
ANDROID_RES = REPO_ROOT / "android" / "app" / "src" / "main" / "res"

SPLASH_SRC = REPO_ROOT / "assets" / "logo" / "fitness_diary_splash.png"

# Android 12+ splash render sizes (px) — match the platform's 240dp / 288dp.
SPLASH_SIZES = {
    "mdpi": 192,
    "hdpi": 256,
    "xhdpi": 384,
    "xxhdpi": 512,
    "xxxhdpi": 768,
}

# Fraction of canvas occupied by the diary. 0.65 leaves a generous
# safe-area margin around the logo so Android's circular mask clips
# nothing important (rings, strap, bookmark).
LOGO_FRACTION = 0.65

# Soft elliptical shadow color (subtle dark red so it blends with the
# OS splash background #450A0A).
SHADOW_COLOR = (0x1A, 0x00, 0x00)


def _soft_shadow(canvas: Image.Image, logo_box: tuple[int, int, int, int]) -> None:
    """Draw a soft elliptical drop shadow under the logo. Mutates
    `canvas` in place by alpha-compositing the shadow on top."""
    lx0, ly0, lx1, ly1 = logo_box
    cx = (lx0 + lx1) / 2
    logo_w = lx1 - lx0
    sw = logo_w * 1.05
    sh = logo_w * 0.10
    sx0 = int(cx - sw / 2)
    sx1 = int(cx + sw / 2)
    sy0 = ly1 - int(sh * 0.20)
    sy1 = sy0 + int(sh)

    shadow_layer = Image.new("RGBA", canvas.size, (0, 0, 0, 0))
    draw = ImageDraw.Draw(shadow_layer)
    for i in range(8, 0, -1):
        a = int(34 * (i / 8))
        shrink = 1.0 - (i / 8) * 0.25
        x0 = int(cx - sw * shrink / 2)
        x1 = int(cx + sw * shrink / 2)
        y0 = sy0 + int((1 - shrink) * sh / 2)
        y1 = sy1 - int((1 - shrink) * sh / 2)
        draw.ellipse([x0, y0, x1, y1], fill=SHADOW_COLOR + (a,))
    canvas.alpha_composite(shadow_layer)


def main() -> None:
    if not SPLASH_SRC.exists():
        raise SystemExit(f"Splash source not found: {SPLASH_SRC}")

    with Image.open(SPLASH_SRC) as raw:
        splash_source = raw.convert("RGBA")

    written: list[Path] = []
    for density, size in SPLASH_SIZES.items():
        canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))

        target = int(size * LOGO_FRACTION)
        scaled = splash_source.copy()
        scaled.thumbnail((target, target), Image.LANCZOS)
        ox = (size - scaled.width) // 2
        oy = (size - scaled.height) // 2
        logo_box = (ox, oy, ox + scaled.width, oy + scaled.height)

        # Soft drop shadow first (under the diary), then the diary on top.
        _soft_shadow(canvas, logo_box)
        canvas.alpha_composite(scaled, (ox, oy))

        light = ANDROID_RES / f"drawable-{density}" / "android12splash.png"
        canvas.save(light, "PNG", optimize=True)
        written.append(light)

        dark = ANDROID_RES / f"drawable-night-{density}" / "android12splash.png"
        canvas.save(dark, "PNG", optimize=True)
        written.append(dark)

    print(f"Wrote {len(written)} files:")
    for path in written:
        print(f"  {path.relative_to(REPO_ROOT)}")


if __name__ == "__main__":
    main()
