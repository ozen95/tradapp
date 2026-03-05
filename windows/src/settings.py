import json
import os

APP_DIR = os.path.join(os.environ.get('APPDATA', '.'), 'TradApp')
SETTINGS_PATH = os.path.join(APP_DIR, 'settings.json')

DEFAULTS = {
    'target_language': 'fr',
    'hotkey': '<ctrl>+<shift>+t',
    'ocr_hotkey': '<ctrl>+<shift>+o',
    'gemini_api_key': '',
    'tone': 'poli',
    'gender': 'masculin',
}


class Settings:
    def __init__(self):
        os.makedirs(APP_DIR, exist_ok=True)
        self._d = dict(DEFAULTS)
        try:
            with open(SETTINGS_PATH, 'r', encoding='utf-8') as f:
                self._d.update(json.load(f))
        except Exception:
            pass

    def get(self, key):
        return self._d.get(key, DEFAULTS.get(key, ''))

    def set(self, key, value):
        self._d[key] = value
        self.save()

    def save(self):
        with open(SETTINGS_PATH, 'w', encoding='utf-8') as f:
            json.dump(self._d, f, ensure_ascii=False, indent=2)
