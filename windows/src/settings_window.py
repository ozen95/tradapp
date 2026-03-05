import tkinter as tk
from tkinter import ttk

from languages import LANGUAGES

BG = '#2b2b2b'
BG2 = '#383838'
FG = '#dddddd'
ACCENT = '#0078d4'


class SettingsWindow:
    def __init__(self, root, settings, on_restart_hotkeys):
        self.root = root
        self.settings = settings
        self.on_restart = on_restart_hotkeys

        # Prevent duplicate windows
        if hasattr(root, '_settings_win') and root._settings_win:
            try:
                root._settings_win.win.lift()
                return
            except Exception:
                pass
        root._settings_win = self

        self.win = tk.Toplevel(root)
        self.win.protocol('WM_DELETE_WINDOW', self._close)
        self._build()

    def _label(self, parent, text, row):
        tk.Label(
            parent, text=text, bg=BG, fg=FG,
            font=('Segoe UI', 10), anchor='w',
        ).grid(row=row, column=0, sticky='w', pady=7, padx=(0, 12))

    def _entry(self, parent, var, row, show=None):
        e = tk.Entry(
            parent, textvariable=var,
            bg=BG2, fg='#ffffff',
            font=('Segoe UI', 10),
            relief='flat', bd=6,
            insertbackground='white',
            show=show,
        )
        e.grid(row=row, column=1, sticky='ew', pady=7)
        return e

    def _build(self):
        win = self.win
        win.title('TradApp — Préférences')
        win.configure(bg=BG)
        win.resizable(False, False)
        win.attributes('-topmost', True)

        frame = tk.Frame(win, bg=BG, padx=24, pady=20)
        frame.pack(fill='both', expand=True)
        frame.columnconfigure(1, weight=1)

        # Title
        tk.Label(
            frame, text='Préférences', bg=BG, fg='#ffffff',
            font=('Segoe UI', 14, 'bold'),
        ).grid(row=0, column=0, columnspan=2, sticky='w', pady=(0, 16))

        # Language
        self._label(frame, 'Langue cible', 1)
        lang_labels = [f"{f}  {n}" for _, f, n, _ in LANGUAGES]
        lang_ids = [lid for lid, *_ in LANGUAGES]
        self.lang_combo = ttk.Combobox(
            frame, values=lang_labels,
            state='readonly', font=('Segoe UI', 10), width=30,
        )
        cur = self.settings.get('target_language')
        idx = next((i for i, lid in enumerate(lang_ids) if lid == cur), 0)
        self.lang_combo.current(idx)
        self.lang_combo.grid(row=1, column=1, sticky='ew', pady=7)
        self._lang_ids = lang_ids

        # Hotkeys
        self._label(frame, 'Raccourci traduction', 2)
        self.hotkey_var = tk.StringVar(value=self.settings.get('hotkey'))
        self._entry(frame, self.hotkey_var, 2)

        self._label(frame, 'Raccourci OCR', 3)
        self.ocr_var = tk.StringVar(value=self.settings.get('ocr_hotkey'))
        self._entry(frame, self.ocr_var, 3)

        # Gemini key
        self._label(frame, 'Clé API Gemini', 4)
        self.gemini_var = tk.StringVar(value=self.settings.get('gemini_api_key'))
        self._entry(frame, self.gemini_var, 4, show='*')

        tk.Label(
            frame,
            text='Optionnel — meilleure qualité. Gratuit sur aistudio.google.com',
            bg=BG, fg='#666666', font=('Segoe UI', 8),
        ).grid(row=5, column=1, sticky='w')

        # Tone
        self._label(frame, 'Ton', 6)
        self.tone_var = tk.StringVar(value=self.settings.get('tone'))
        tone_f = tk.Frame(frame, bg=BG)
        tone_f.grid(row=6, column=1, sticky='w', pady=7)
        for val, label in [('poli', 'Formel'), ('casual', 'Familier')]:
            tk.Radiobutton(
                tone_f, text=label, variable=self.tone_var, value=val,
                bg=BG, fg=FG, selectcolor=BG2,
                activebackground=BG, activeforeground='#ffffff',
                font=('Segoe UI', 10),
            ).pack(side='left', padx=8)

        # Gender (Thai)
        self._label(frame, 'Genre (thaï)', 7)
        self.gender_var = tk.StringVar(value=self.settings.get('gender'))
        gender_f = tk.Frame(frame, bg=BG)
        gender_f.grid(row=7, column=1, sticky='w', pady=7)
        for val, label in [('masculin', 'Masculin  ครับ'), ('feminin', 'Féminin  ค่ะ')]:
            tk.Radiobutton(
                gender_f, text=label, variable=self.gender_var, value=val,
                bg=BG, fg=FG, selectcolor=BG2,
                activebackground=BG, activeforeground='#ffffff',
                font=('Segoe UI', 10),
            ).pack(side='left', padx=8)

        # Save button
        tk.Button(
            frame, text='Enregistrer',
            command=self._save,
            bg=ACCENT, fg='white',
            font=('Segoe UI', 10, 'bold'),
            relief='flat', padx=20, pady=8,
            cursor='hand2', borderwidth=0,
            activebackground='#106ebe', activeforeground='white',
        ).grid(row=8, column=0, columnspan=2, pady=(20, 0))

        # Center window
        win.update_idletasks()
        w, h = win.winfo_reqwidth(), win.winfo_reqheight()
        sw, sh = win.winfo_screenwidth(), win.winfo_screenheight()
        win.geometry(f'{w}x{h}+{(sw - w) // 2}+{(sh - h) // 2}')

    def _save(self):
        self.settings.set('target_language', self._lang_ids[self.lang_combo.current()])
        self.settings.set('hotkey', self.hotkey_var.get().strip())
        self.settings.set('ocr_hotkey', self.ocr_var.get().strip())
        self.settings.set('gemini_api_key', self.gemini_var.get().strip())
        self.settings.set('tone', self.tone_var.get())
        self.settings.set('gender', self.gender_var.get())
        self.on_restart()
        self._close()

    def _close(self):
        self.root._settings_win = None
        self.win.destroy()
