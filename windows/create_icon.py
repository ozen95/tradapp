"""Generate resources/icon.ico for TradApp Windows."""
import os
from PIL import Image, ImageDraw


def create_ico():
    os.makedirs('resources', exist_ok=True)
    sizes = [16, 24, 32, 48, 64, 128, 256]
    images = []

    for size in sizes:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)

        m = max(1, size // 20)
        # Background circle — dark
        draw.ellipse([m, m, size - m, size - m], fill=(28, 28, 28, 255))

        # "T" — white
        bw = int(size * 0.58)
        bh = max(2, int(size * 0.12))
        bx = (size - bw) // 2
        by = int(size * 0.24)
        # Horizontal bar
        draw.rectangle([bx, by, bx + bw, by + bh], fill=(255, 255, 255, 255))
        # Vertical stem
        sw = max(2, int(size * 0.14))
        sx = (size - sw) // 2
        draw.rectangle([sx, by, sx + sw, int(size * 0.76)], fill=(255, 255, 255, 255))

        images.append(img)

    images[0].save(
        'resources/icon.ico',
        format='ICO',
        sizes=[(s, s) for s in sizes],
        append_images=images[1:],
    )
    print('✅ resources/icon.ico créé')


if __name__ == '__main__':
    create_ico()
