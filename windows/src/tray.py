import threading
import pystray
from PIL import Image, ImageDraw

from languages import LANGUAGES


def _create_icon_image():
    size = 64
    img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    # Dark circle background
    draw.ellipse([2, 2, size - 2, size - 2], fill=(28, 28, 28, 255))
    # White "T" letter
    bar_w, bar_h = 36, 7
    bx = (size - bar_w) // 2
    # Horizontal bar
    draw.rectangle([bx, 16, bx + bar_w, 16 + bar_h], fill=(255, 255, 255, 255))
    # Vertical stem
    sw = 8
    sx = (size - sw) // 2
    draw.rectangle([sx, 16, sx + sw, 50], fill=(255, 255, 255, 255))
    return img


class TradTray:
    def __init__(self, settings, history, queue):
        self.settings = settings
        self.history = history
        self.q = queue
        self.icon = None

    def _lang_menu(self):
        items = []
        for lang_id, flag, native, _ in LANGUAGES:
            def make_cb(lid=lang_id):
                def cb(icon, item):
                    self.settings.set('target_language', lid)
                return cb

            items.append(pystray.MenuItem(
                f"{flag}  {native}",
                make_cb(),
                checked=lambda item, lid=lang_id: self.settings.get('target_language') == lid,
                radio=True,
            ))
        return items

    def _build_menu(self):
        return pystray.Menu(
            pystray.MenuItem(
                'Traduire le texte sélectionné',
                lambda icon, item: self.q.put(('translate',))
            ),
            pystray.MenuItem(
                'OCR — Zone d\'écran',
                lambda icon, item: self.q.put(('ocr',))
            ),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem(
                'Langue cible',
                pystray.Menu(*self._lang_menu())
            ),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem(
                'Historique',
                lambda icon, item: self.q.put(('history',))
            ),
            pystray.MenuItem(
                'Préférences',
                lambda icon, item: self.q.put(('settings',))
            ),
            pystray.Menu.SEPARATOR,
            pystray.MenuItem(
                'Quitter',
                lambda icon, item: self.q.put(('quit',))
            ),
        )

    def run(self):
        self.icon = pystray.Icon(
            'TradApp',
            _create_icon_image(),
            'TradApp',
            menu=self._build_menu(),
        )
        self.icon.run()

    def stop(self):
        if self.icon:
            try:
                self.icon.stop()
            except Exception:
                pass
