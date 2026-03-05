import json
import os

APP_DIR = os.path.join(os.environ.get('APPDATA', '.'), 'TradApp')
HISTORY_PATH = os.path.join(APP_DIR, 'history.json')
MAX_ENTRIES = 50


class History:
    def __init__(self):
        os.makedirs(APP_DIR, exist_ok=True)
        self._entries = []
        self._load()

    def _load(self):
        try:
            with open(HISTORY_PATH, 'r', encoding='utf-8') as f:
                self._entries = json.load(f)
        except Exception:
            self._entries = []

    def _save(self):
        try:
            with open(HISTORY_PATH, 'w', encoding='utf-8') as f:
                json.dump(self._entries, f, ensure_ascii=False, indent=2)
        except Exception:
            pass

    def add(self, original, translated, source_lang, target_lang):
        self._entries.insert(0, {
            'original': original,
            'translated': translated,
            'source_lang': source_lang or '?',
            'target_lang': target_lang,
        })
        self._entries = self._entries[:MAX_ENTRIES]
        self._save()

    def all(self):
        return list(self._entries)

    def clear(self):
        self._entries = []
        self._save()
