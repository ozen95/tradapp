"""
TradApp — Windows
Traduction instantanée via raccourci clavier, depuis la barre des tâches.
"""

import sys
import os
import queue
import threading
import time
import tkinter as tk

import pyperclip
from pynput.keyboard import Controller as KbController, Key

from settings import Settings
from history import History
from translator import translate
from hotkeys import HotkeyManager
from tray import TradTray
from popup import TranslationPopup
from ocr import OCROverlay, HAS_OCR
from settings_window import SettingsWindow
from history_window import HistoryWindow

_kb = KbController()


def _get_selected_text():
    """Copy selected text via Ctrl+C clipboard trick."""
    try:
        prev = pyperclip.paste()
    except Exception:
        prev = ''

    pyperclip.copy('')
    time.sleep(0.05)

    # Simulate Ctrl+C (release any held modifiers first)
    _kb.release(Key.ctrl)
    _kb.release(Key.shift)
    with _kb.pressed(Key.ctrl):
        _kb.press('c')
        _kb.release('c')

    time.sleep(0.18)

    try:
        text = pyperclip.paste()
    except Exception:
        text = ''

    if not text and prev:
        pyperclip.copy(prev)

    return text.strip()


class App:
    def __init__(self):
        self.settings = Settings()
        self.history = History()
        self.q = queue.Queue()

        # Hidden tkinter root — all windows are Toplevel children of this
        self.root = tk.Tk()
        self.root.withdraw()
        self.root.title('TradApp')
        self.root.protocol('WM_DELETE_WINDOW', lambda: None)

        # System tray (background thread)
        self.tray = TradTray(self.settings, self.history, self.q)
        threading.Thread(target=self.tray.run, daemon=True).start()

        # Global hotkeys (background thread)
        self.hotkeys = HotkeyManager(
            self.settings,
            on_translate=lambda: self.q.put(('translate',)),
            on_ocr=lambda: self.q.put(('ocr',)),
        )
        self.hotkeys.start()

        # Start polling the queue
        self.root.after(100, self._poll)
        self.root.mainloop()

    # ── Queue polling ──────────────────────────────────────────────────────────

    def _poll(self):
        try:
            while True:
                msg = self.q.get_nowait()
                action = msg[0]
                if action == 'translate':
                    self._do_translate()
                elif action == 'ocr':
                    self._do_ocr()
                elif action == 'show_popup':
                    self._show_popup(*msg[1:])
                elif action == 'settings':
                    SettingsWindow(self.root, self.settings, self.hotkeys.restart)
                elif action == 'history':
                    HistoryWindow(self.root, self.history)
                elif action == 'quit':
                    self._quit()
                    return
        except queue.Empty:
            pass
        self.root.after(100, self._poll)

    # ── Actions ────────────────────────────────────────────────────────────────

    def _do_translate(self):
        def worker():
            text = _get_selected_text()
            if not text:
                return

            def on_result(translated, source_lang):
                if translated:
                    self.history.add(
                        text, translated, source_lang,
                        self.settings.get('target_language'),
                    )
                    self.q.put(('show_popup', translated, source_lang, text))

            translate(text, self.settings, on_result)

        threading.Thread(target=worker, daemon=True).start()

    def _do_ocr(self):
        if not HAS_OCR:
            self._alert(
                'OCR indisponible',
                'Tesseract n\'est pas installé.\n'
                'Télécharge le .exe sur github.com/tesseract-ocr/tesseract',
            )
            return
        OCROverlay(self.root, self._on_ocr_text)

    def _on_ocr_text(self, text):
        if not text:
            return

        def on_result(translated, source_lang):
            if translated:
                self.history.add(
                    text, translated, source_lang,
                    self.settings.get('target_language'),
                )
                self.q.put(('show_popup', translated, source_lang, text))

        translate(text, self.settings, on_result)

    def _show_popup(self, translated, source_lang, original):
        target = self.settings.get('target_language')

        def swap():
            if source_lang:
                self.settings.set('target_language', source_lang)
            self.q.put(('translate',))

        TranslationPopup(
            self.root, translated, source_lang, original, target,
            on_swap=swap,
        )

    def _alert(self, title, message):
        win = tk.Toplevel(self.root)
        win.title(f'TradApp — {title}')
        win.configure(bg='#2b2b2b')
        win.attributes('-topmost', True)
        tk.Label(
            win, text=message,
            bg='#2b2b2b', fg='#ff6b6b',
            font=('Segoe UI', 11),
            padx=24, pady=20, justify='left',
        ).pack()
        tk.Button(
            win, text='OK', command=win.destroy,
            bg='#3a3a3a', fg='white',
            font=('Segoe UI', 10),
            relief='flat', padx=20, pady=6,
            cursor='hand2', borderwidth=0,
        ).pack(pady=(0, 16))
        win.update_idletasks()
        w, h = win.winfo_reqwidth(), win.winfo_reqheight()
        sw, sh = win.winfo_screenwidth(), win.winfo_screenheight()
        win.geometry(f'{w}x{h}+{(sw - w) // 2}+{(sh - h) // 2}')

    def _quit(self):
        self.tray.stop()
        self.hotkeys.stop()
        self.root.quit()


if __name__ == '__main__':
    App()
