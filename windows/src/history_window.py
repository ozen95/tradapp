import tkinter as tk
import pyperclip

BG = '#1e1e1e'
BG_ALT = '#252525'
FG = '#ffffff'
FG_DIM = '#888888'
FG_ORIG = '#666666'


class HistoryWindow:
    def __init__(self, root, history):
        self.root = root
        self.history = history

        if hasattr(root, '_history_win') and root._history_win:
            try:
                root._history_win.win.lift()
                return
            except Exception:
                pass
        root._history_win = self

        self.win = tk.Toplevel(root)
        self.win.protocol('WM_DELETE_WINDOW', self._close)
        self._build()

    def _build(self):
        win = self.win
        win.title('TradApp — Historique')
        win.configure(bg=BG)
        win.attributes('-topmost', True)
        win.geometry('520x440')

        # Scrollable area
        container = tk.Frame(win, bg=BG)
        container.pack(fill='both', expand=True)

        scrollbar = tk.Scrollbar(container, bg=BG, troughcolor='#2a2a2a')
        scrollbar.pack(side='right', fill='y')

        canvas = tk.Canvas(
            container, bg=BG,
            yscrollcommand=scrollbar.set,
            highlightthickness=0,
        )
        canvas.pack(side='left', fill='both', expand=True)
        scrollbar.config(command=canvas.yview)

        inner = tk.Frame(canvas, bg=BG)
        win_id = canvas.create_window((0, 0), window=inner, anchor='nw')

        entries = self.history.all()

        if not entries:
            tk.Label(
                inner,
                text='Aucune traduction dans l\'historique.',
                bg=BG, fg=FG_DIM,
                font=('Segoe UI', 11),
                pady=40,
            ).pack()
        else:
            for i, entry in enumerate(entries):
                self._row(inner, entry, i)

        def on_inner_configure(e):
            canvas.configure(scrollregion=canvas.bbox('all'))

        def on_canvas_configure(e):
            canvas.itemconfig(win_id, width=e.width)

        inner.bind('<Configure>', on_inner_configure)
        canvas.bind('<Configure>', on_canvas_configure)
        canvas.bind('<MouseWheel>', lambda e: canvas.yview_scroll(-1 * (e.delta // 120), 'units'))

    def _row(self, parent, entry, idx):
        bg = BG_ALT if idx % 2 == 0 else BG
        frame = tk.Frame(parent, bg=bg, padx=14, pady=9)
        frame.pack(fill='x')

        # Direction badge
        src = entry.get('source_lang', '?')
        tgt = entry.get('target_lang', '?')
        tk.Label(
            frame, text=f"{src} → {tgt}",
            bg=bg, fg='#555555',
            font=('Segoe UI', 8),
        ).pack(anchor='w')

        # Original
        tk.Label(
            frame, text=entry.get('original', ''),
            bg=bg, fg=FG_ORIG,
            font=('Segoe UI', 9),
            wraplength=460, justify='left', anchor='w',
        ).pack(fill='x')

        # Translated + copy button
        row = tk.Frame(frame, bg=bg)
        row.pack(fill='x', pady=(3, 0))

        tk.Label(
            row, text=entry.get('translated', ''),
            bg=bg, fg=FG,
            font=('Segoe UI', 11),
            wraplength=430, justify='left', anchor='w',
        ).pack(side='left', fill='x', expand=True)

        translated = entry.get('translated', '')
        tk.Button(
            row, text='⎘',
            command=lambda t=translated: pyperclip.copy(t),
            bg=bg, fg=FG_DIM,
            font=('Segoe UI', 11),
            relief='flat', padx=4, pady=0,
            cursor='hand2', borderwidth=0,
            activebackground=bg, activeforeground=FG,
        ).pack(side='right')

    def _close(self):
        self.root._history_win = None
        self.win.destroy()
