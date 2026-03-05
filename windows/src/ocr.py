import sys
import os
import threading
import tkinter as tk
from PIL import ImageGrab

# Locate Tesseract — handles both dev and PyInstaller frozen builds
try:
    import pytesseract

    if getattr(sys, 'frozen', False):
        _base = sys._MEIPASS
        _tess_exe = os.path.join(_base, 'tesseract.exe')
        if os.path.exists(_tess_exe):
            pytesseract.pytesseract.tesseract_cmd = _tess_exe
    HAS_OCR = True
except ImportError:
    HAS_OCR = False

BG_OVERLAY = 'black'
INSTR = 'Dessinez un rectangle — Échap pour annuler'


class OCROverlay:
    """Fullscreen overlay for region selection + OCR."""

    def __init__(self, root, callback):
        self.root = root
        self.callback = callback
        self._start = None
        self._rect_id = None

        self.win = tk.Toplevel(root)
        self._build()

    def _build(self):
        win = self.win
        win.attributes('-fullscreen', True)
        win.attributes('-topmost', True)
        win.attributes('-alpha', 0.38)
        win.configure(bg=BG_OVERLAY)
        win.overrideredirect(True)

        self.canvas = tk.Canvas(
            win, bg=BG_OVERLAY,
            cursor='crosshair',
            highlightthickness=0,
        )
        self.canvas.pack(fill='both', expand=True)

        # Instructions
        sw = win.winfo_screenwidth()
        self.canvas.create_text(
            sw // 2, 60,
            text=INSTR,
            fill='white',
            font=('Segoe UI', 15, 'bold'),
        )

        self.canvas.bind('<ButtonPress-1>', self._press)
        self.canvas.bind('<B1-Motion>', self._drag)
        self.canvas.bind('<ButtonRelease-1>', self._release)
        win.bind('<Escape>', lambda e: self._cancel())
        win.focus_force()

    def _press(self, event):
        self._start = (event.x_root, event.y_root)
        if self._rect_id:
            self.canvas.delete(self._rect_id)

    def _drag(self, event):
        if not self._start:
            return
        if self._rect_id:
            self.canvas.delete(self._rect_id)
        ox = self._start[0] - self.win.winfo_rootx()
        oy = self._start[1] - self.win.winfo_rooty()
        self._rect_id = self.canvas.create_rectangle(
            ox, oy, event.x, event.y,
            outline='white', width=2, fill='',
        )

    def _release(self, event):
        if not self._start:
            return
        x0 = min(self._start[0], event.x_root)
        y0 = min(self._start[1], event.y_root)
        x1 = max(self._start[0], event.x_root)
        y1 = max(self._start[1], event.y_root)
        self._start = None

        if x1 - x0 < 10 or y1 - y0 < 10:
            return

        self.win.destroy()
        self.root.after(250, lambda: self._capture(x0, y0, x1, y1))

    def _cancel(self):
        self.win.destroy()
        self.callback(None)

    def _capture(self, x0, y0, x1, y1):
        def run():
            try:
                img = ImageGrab.grab(bbox=(x0, y0, x1, y1), all_screens=True)
                if not HAS_OCR:
                    self.root.after(0, lambda: self.callback(None))
                    return
                # Use multiple languages for better accuracy
                text = pytesseract.image_to_string(img, lang='fra+eng+deu+spa+jpn')
                text = text.strip()
                self.root.after(0, lambda: self.callback(text if text else None))
            except Exception as e:
                print(f"[OCR] {e}")
                self.root.after(0, lambda: self.callback(None))

        threading.Thread(target=run, daemon=True).start()
