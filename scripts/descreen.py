#!/usr/bin/env python3
"""Remove the LCD pixel grid from a phone photo of a computer screen.

Usage: scripts/descreen.py IN.jpg OUT.png
       scripts/descreen.py --self-test

When someone photographs the Zoom gallery instead of screenshotting it, the
screen's subpixel grid lands in the photo as fine evenly spaced lines. Blurring
hides them only by softening every face. They are periodic, though, so in the
Fourier domain they sit in a narrow band (about 0.21 to 0.32 cycles/px, i.e. a
3 to 5px pitch, drifting with the camera angle) close to each axis. Zeroing
that band removes the grid and leaves real detail, which is spread across all
frequencies, almost untouched.

Deterministic filtering, no AI: no face or label is redrawn, which keeps this
within prime directive 1. Straighten, crop and colour-correct afterwards with
ImageMagick (see README.md, "Photo of a screen instead of a screenshot").

If a grid survives, its pitch is outside the band: widen LO/HI below.
Needs numpy and Pillow (brew install numpy pillow).
"""
import sys

import numpy as np
from PIL import Image, ImageFilter

LO, HI = 0.21, 0.32  # band to notch, cycles/px along an axis
SPREAD = 0.07  # how far off-axis the band reaches, cycles/px


def descreen(img: np.ndarray) -> np.ndarray:
    h, w = img.shape[:2]
    fy = np.abs(np.fft.fftfreq(h))[:, None]
    fx = np.abs(np.fft.fftfreq(w))[None, :]
    notch = ((fx >= LO) & (fx <= HI) & (fy < SPREAD)) | (
        (fy >= LO) & (fy <= HI) & (fx < SPREAD)
    )
    # Feather the notch edges so the filter doesn't ring around sharp edges.
    mask = Image.fromarray((~notch * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(3))
    mask = np.asarray(mask, dtype=np.float64) / 255
    out = np.empty(img.shape, dtype=np.float64)
    for c in range(img.shape[2]):
        out[:, :, c] = np.real(np.fft.ifft2(np.fft.fft2(img[:, :, c]) * mask))
    return np.clip(out, 0, 255)


def self_test() -> None:
    # A smooth gradient plus a 3.7px vertical grid: the grid must go, the gradient must stay.
    h, w = 256, 256
    x = np.arange(w)[None, :, None]
    base = np.broadcast_to(np.linspace(60, 200, w)[None, :, None], (h, w, 3))
    grid = 30 * np.sin(2 * np.pi * x / 3.7)
    out = descreen(base + grid)
    inner = (slice(16, -16), slice(16, -16))  # FFT wraps at the borders
    residual = np.abs(out - base)[inner].mean()
    assert residual < 3, f"grid survived: mean error {residual:.1f}"
    print(f"ok (residual {residual:.2f} of 30)")


if __name__ == "__main__":
    if sys.argv[1:] == ["--self-test"]:
        self_test()
    elif len(sys.argv) == 3:
        src = np.asarray(Image.open(sys.argv[1]).convert("RGB"), dtype=np.float64)
        Image.fromarray(descreen(src).astype(np.uint8)).save(sys.argv[2])
    else:
        sys.exit(__doc__)
