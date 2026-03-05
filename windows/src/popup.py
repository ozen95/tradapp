import tkinter as tk
import pyperclip

from languages import find_language

BG = '#1e1e1e'
BG2 = '#2a2a2a'
FG = '#ffffff'
FG_DIM = '#888888'
ACCENT = '#0078d4'
BTN_BG = '#333333'


class TranslationPopup:
    def __init__(self, root, translated, source_lang, original, target_lang, on_swap=None):
        self.root = root
        self.translated = translated
        self.on_swap = on_swap

        self.win = tk.Toplevel(root)
        self._build(translated, source_lang, original, target_lang)

    def _build(self, translated, source_lang, original, target_lang):
        win = self.win
        win.overrideredirect(True)
        win.attributes('-topmost', True)
        win.attributes('-alpha', 0.97)
        win.configure(bg=BG)

        outer = tk.Frame(win, bg='#444444', padx=1, pady=1)
        outer.pack(fill='both', expand=True)

        frame = tk.Frame(outer, bg=BG, padx=16, pady=12)
        frame.pack(fill='both', expand=True)

        # Header: source lang badge
        header = tk.Frame(frame, bg=BG)
        header.pack(fill='x', pady=(0, 8))

        src = find_language(source_lang) if source_lang else None
        badge_text = f"  {src[1]} {src[0].upper()}  " if src else "  ?  "
        tk.Label(
            header, text=badge_text,
            bg=BG2, fg=FG_DIM,
            font=('Segoe UI', 9),
            padx=4, pady=2,
        ).pack(side='left')

        tgt = find_language(target_lang)
        if tgt:
            tk.Label(
                header, text=f"  →  {tgt[1]} {tgt[0].upper()}  ",
                bg=BG2, fg=FG_DIM,
                font=('Segoe UI', 9),
                padx=4, pady=2,
            ).pack(side='left', padx=(4, 0))

        # Translated text (read-only Text widget for word wrap)
        text_w = tk.Text(
            frame,
            bg=BG, fg=FG,
            font=('Segoe UI', 13),
            wrap='word',
            relief='flat',
            borderwidth=0,
            width=38,
            height=min(6, max(2, translated.count('\n') + 2)),
            padx=0, pady=4,
            cursor='arrow',
        )
        text_w.insert('1.0', translated)
        text_w.configure(state='disabled')
        text_w.pack(fill='both', expand=True)

        # Button row
        btn_row = tk.Frame(frame, bg=BG)
        btn_row.pack(fill='x', pady=(10, 0))

        def copy():
            pyperclip.copy(self.translated)
            copy_btn.configure(text='✓ Copié !')
            win.after(1800, lambda: copy_btn.configure(text='⎘ Copier'))

        copy_btn = self._btn(btn_row, '⎘ Copier', copy)
        copy_btn.pack(side='left', padx=(0, 6))

        if self.on_swap:
            swap_btn = self._btn(btn_row, '⇄ Swap', lambda: [self.close(), self.on_swap()])
            swap_btn.pack(side='left')

        close_btn = tk.Button(
            btn_row, text='✕',
            command=self.close,
            bg=BG, fg=FG_DIM,
            font=('Segoe UI', 10),
            relief='flat', padx=6, pady=3,
            cursor='hand2', borderwidth=0,
            activebackground=BG, activeforeground=FG,
        )
        close_btn.pack(side='right')

        # Position near cursor
        win.update_idletasks()
        w = win.winfo_reqwidth()
        h = win.winfo_reqheight()
        cx = win.winfo_pointerx() + 12
        cy = win.winfo_pointery() + 12
        sw = win.winfo_screenwidth()
        sh = win.winfo_screenheight()
        if cx + w > sw - 10:
            cx = sw - w - 10
        if cy + h > sh - 50:
            cy = cy - h - 24
        win.geometry(f'+{cx}+{cy}')

        win.bind('<FocusOut>', lambda e: win.after(300, self._check_focus))
        win.focus_force()
        win.after(20000, self.close)  # auto-close after 20s

    def _btn(self, parent, text, cmd):
        return tk.Button(
            parent, text=text, command=cmd,
            bg=BTN_BG, fg=FG,
            font=('Segoe UI', 9),
            relief='flat', padx=10, pady=4,
            cursor='hand2', borderwidth=0,
            activebackground='#444444', activeforeground=FG,
        )

    def _check_focus(self):
        try:
            focused = str(self.win.focus_get())
            if focused not in [str(self.win), str(self.win) + '.!frame', '']:
                pass  # keep open if child widget has focus
        except Exception:
            self.close()

    def close(self):
        try:
            self.win.destroy()
        except Exception:
            pass
