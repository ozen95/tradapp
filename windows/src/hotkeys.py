import threading
from pynput import keyboard


class HotkeyManager:
    def __init__(self, settings, on_translate, on_ocr):
        self.settings = settings
        self.on_translate = on_translate
        self.on_ocr = on_ocr
        self._listener = None

    def _build(self):
        mapping = {}
        translate_combo = self.settings.get('hotkey')
        ocr_combo = self.settings.get('ocr_hotkey')
        if translate_combo:
            mapping[translate_combo] = self.on_translate
        if ocr_combo:
            mapping[ocr_combo] = self.on_ocr
        return mapping

    def start(self):
        self.stop()
        mapping = self._build()
        if not mapping:
            return
        try:
            self._listener = keyboard.GlobalHotKeys(mapping)
            threading.Thread(target=self._listener.start, daemon=True).start()
        except Exception as e:
            print(f"[Hotkeys] {e}")

    def stop(self):
        if self._listener:
            try:
                self._listener.stop()
            except Exception:
                pass
            self._listener = None

    def restart(self):
        self.start()
