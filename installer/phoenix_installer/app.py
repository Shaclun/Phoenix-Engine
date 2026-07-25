"""Tkinter wizard and management panel for Phoenix Engine."""

from __future__ import annotations

import queue
import threading
import tkinter as tk
import traceback
from pathlib import Path
from tkinter import filedialog, messagebox, simpledialog, ttk
from typing import Any, Callable

from .core import (DBConfig, DatabaseResetPreflight, DiagnosticItem,
                   PhoenixCore, ServerConfig, build_web_archive, format_command, generate_password,
                   load_db_config, load_server_config, resource_path,
                   save_db_config, save_server_config, validate_db_config,
                   validate_server_config)
from .i18n import LANGUAGES, tr

THEMES = {
    "light": {
        "bg": "#f5f5f7", "panel": "#ffffff", "surface": "#e8e8ed",
        "surface_hover": "#dcdce2", "surface_disabled": "#efeff2",
        "accent": "#0071e3", "accent_hover": "#0077ed", "accent_soft": "#d9ebff",
        "text": "#1d1d1f", "muted": "#6e6e73", "disabled": "#a1a1a6",
        "field": "#ffffff", "border": "#d2d2d7", "log": "#f0f0f3",
        "log_text": "#323234", "danger": "#d70015", "danger_hover": "#b60012",
        "danger_text": "#ffffff", "ok": "#248a3d", "warn": "#b25000", "error": "#d70015",
    },
    "dark": {
        "bg": "#000000", "panel": "#1c1c1e", "surface": "#2c2c2e",
        "surface_hover": "#3a3a3c", "surface_disabled": "#1f1f21",
        "accent": "#0a84ff", "accent_hover": "#409cff", "accent_soft": "#12395f",
        "text": "#f5f5f7", "muted": "#a1a1a6", "disabled": "#636366",
        "field": "#1c1c1e", "border": "#3a3a3c", "log": "#111113",
        "log_text": "#e5e5ea", "danger": "#ff453a", "danger_hover": "#ff6961",
        "danger_text": "#ffffff", "ok": "#30d158", "warn": "#ff9f0a", "error": "#ff453a",
    },
}


def _activate_palette(name: str) -> dict[str, str]:
    """Expose the active palette to legacy dynamic widget builders."""
    global BG, PANEL, PANEL_2, GOLD, ORANGE, TEXT, MUTED, OK, WARN, ERROR
    colors = THEMES[name]
    BG, PANEL, PANEL_2 = colors["bg"], colors["panel"], colors["surface"]
    GOLD, ORANGE = colors["accent"], colors["accent"]
    TEXT, MUTED = colors["text"], colors["muted"]
    OK, WARN, ERROR = colors["ok"], colors["warn"], colors["error"]
    return colors


DEFAULT_THEME = "dark"
_activate_palette(DEFAULT_THEME)


class PhoenixInstaller(tk.Tk):
    """Single-window, asynchronous Phoenix Engine setup wizard."""

    STEP_KEYS = ("welcome", "project", "server", "diagnostics", "database", "install", "finish")

    def __init__(self) -> None:
        super().__init__()
        self.language = "pl"
        self.theme_name = DEFAULT_THEME
        self.colors = _activate_palette(self.theme_name)
        self.core = PhoenixCore()
        self.step = 0
        self.events: queue.Queue[tuple[str, Any]] = queue.Queue()
        self.busy = False
        self.closed = False
        self.status_level = "ok"
        self.diagnostic_items: list[DiagnosticItem] = []
        self.db_config = load_db_config(self.core.project)
        self.server_config = load_server_config(self.core.project)
        self.logo: tk.PhotoImage | None = None
        self._configure_window()
        self._configure_styles()
        self._build_shell()
        self.render_page()
        self.after(100, self._drain_events)

    def t(self, key: str, **values: object) -> str:
        return tr(self.language, key, **values)

    def report_callback_exception(self, exception: type[BaseException], value: BaseException,
                                  trace: object) -> None:
        """Surface Tk callback failures that PyInstaller windowed builds would hide."""
        traceback.print_exception(exception, value, trace)
        message = f"{exception.__name__}: {value}"
        if hasattr(self, "log_text"):
            self._show_error(message)
        else:
            messagebox.showerror(self.t("app_title"), message, parent=self)

    def _configure_window(self) -> None:
        self.title(self.t("app_title"))
        self.geometry("1040x760")
        self.minsize(860, 650)
        self.configure(bg=self.colors["bg"])
        self.protocol("WM_DELETE_WINDOW", self._request_close)
        try:
            self.logo = tk.PhotoImage(file=str(resource_path("assets/pe.png")))
            self.iconphoto(True, self.logo)
        except (tk.TclError, OSError):
            self.logo = None

    def _configure_styles(self) -> None:
        c = self.colors
        style = ttk.Style(self)
        style.theme_use("clam")
        style.configure("TFrame", background=c["bg"])
        style.configure("Panel.TFrame", background=c["panel"])
        style.configure("TLabel", background=c["bg"], foreground=c["text"], font=("Segoe UI", 10))
        style.configure("Panel.TLabel", background=c["panel"], foreground=c["accent"], font=("Segoe UI", 10, "bold"))
        style.configure("Title.TLabel", background=c["bg"], foreground=c["text"], font=("Segoe UI", 22, "bold"))
        style.configure("Subtitle.TLabel", background=c["bg"], foreground=c["muted"], font=("Segoe UI", 10))
        style.configure("Step.TLabel", background=c["surface"], foreground=c["muted"], padding=(10, 9), font=("Segoe UI", 9, "bold"))
        style.configure("Active.Step.TLabel", background=c["accent"], foreground="#ffffff")
        style.configure("Done.Step.TLabel", background=c["accent_soft"], foreground=c["accent"])
        style.configure("TButton", background=c["surface"], foreground=c["text"], borderwidth=0,
                        focusthickness=0, padding=(14, 9), font=("Segoe UI", 10, "bold"))
        style.map("TButton", background=[("active", c["surface_hover"]), ("disabled", c["surface_disabled"])],
                  foreground=[("disabled", c["disabled"])])
        style.configure("Tool.TButton", padding=(11, 7), font=("Segoe UI", 9, "bold"))
        style.configure("Accent.TButton", background=c["accent"], foreground="#ffffff")
        style.map("Accent.TButton", background=[("active", c["accent_hover"]), ("disabled", c["surface_disabled"])],
                  foreground=[("disabled", c["disabled"])])
        style.configure("Danger.TButton", background=c["danger"], foreground=c["danger_text"])
        style.map("Danger.TButton", background=[("active", c["danger_hover"])])
        style.configure("TEntry", fieldbackground=c["field"], foreground=c["text"], insertcolor=c["text"],
                        bordercolor=c["border"], lightcolor=c["border"], darkcolor=c["border"], padding=8)
        style.configure("TRadiobutton", background=c["bg"], foreground=c["text"], font=("Segoe UI", 11), padding=5)
        style.map("TRadiobutton", background=[("active", c["bg"])], foreground=[("active", c["accent"])])
        style.configure("TCheckbutton", background=c["bg"], foreground=c["text"], font=("Segoe UI", 10), padding=5)
        style.map("TCheckbutton", background=[("active", c["bg"])], foreground=[("active", c["accent"])])
        style.configure("Treeview", background=c["panel"], fieldbackground=c["panel"], foreground=c["text"],
                        rowheight=30, borderwidth=0)
        style.map("Treeview", background=[("selected", c["accent_soft"])], foreground=[("selected", c["text"])])

    def _build_shell(self) -> None:
        header = ttk.Frame(self, padding=(24, 10, 24, 6))
        header.grid(row=0, column=0, sticky="ew")
        if self.logo:
            shown = self.logo.subsample(max(1, self.logo.width() // 76), max(1, self.logo.height() // 76))
            self.header_logo = shown
            ttk.Label(header, image=shown).pack(side="left", padx=(0, 14))
        title_box = ttk.Frame(header)
        title_box.pack(side="left", fill="x", expand=True)
        self.title_label = ttk.Label(title_box, text=self.t("app_title"), style="Title.TLabel")
        self.title_label.pack(anchor="w")
        ttk.Label(title_box, text="Phoenix Engine", style="Subtitle.TLabel").pack(anchor="w")
        self.about_button = ttk.Button(header, text=self.t("about"), command=self._show_about, style="Tool.TButton")
        self.about_button.pack(side="right")
        self.theme_button = ttk.Button(header, command=self._toggle_theme, style="Tool.TButton")
        self.theme_button.pack(side="right", padx=(0, 8))
        self.next_button = ttk.Button(header, text=self.t("next"), style="Accent.TButton", command=self.next_step)
        self.next_button.pack(side="right", padx=(0, 8))
        self.back_button = ttk.Button(header, text=self.t("back"), command=self.previous_step, style="Tool.TButton")
        self.back_button.pack(side="right", padx=(0, 8))
        self.step_bar = ttk.Frame(self, style="Panel.TFrame", padding=6)
        self.step_bar.grid(row=1, column=0, sticky="ew", padx=22)
        self.page = ttk.Frame(self, padding=(28, 10))
        self.page.grid(row=2, column=0, sticky="nsew")
        self.log_frame = ttk.Frame(self, style="Panel.TFrame", padding=(14, 8))
        self.log_frame.grid(row=4, column=0, sticky="ew", padx=22, pady=(0, 6))
        self.log_label = ttk.Label(self.log_frame, text=self.t("operation_log"), style="Panel.TLabel")
        self.log_label.pack(anchor="w")
        self.log_text = tk.Text(self.log_frame, height=2, relief="flat", borderwidth=0,
                                font=("Consolas", 9), wrap="word", state="disabled")
        self.log_text.pack(fill="x", pady=(6, 0))
        footer = ttk.Frame(self, padding=(22, 2, 22, 6))
        footer.grid(row=3, column=0, sticky="ew")
        self.status_label = ttk.Label(footer, text=self.t("ready"), foreground=OK)
        self.status_label.pack(side="left")
        self.copyright_label = ttk.Label(footer, text=self.t("copyright"), foreground=MUTED)
        self.copyright_label.pack(side="left", padx=18)
        self.cancel_button = ttk.Button(footer, text=self.t("cancel"), command=self._request_close)
        self.cancel_button.pack(side="right")
        self.grid_columnconfigure(0, weight=1)
        self.grid_rowconfigure(2, weight=1)
        self._refresh_theme_widgets()

    def _theme_button_text(self) -> str:
        return f"☾ {self.t('theme_dark')}" if self.theme_name == "light" else f"☀ {self.t('theme_light')}"

    def _toggle_theme(self) -> None:
        self.theme_name = "dark" if self.theme_name == "light" else "light"
        self.colors = _activate_palette(self.theme_name)
        self.configure(bg=self.colors["bg"])
        self._configure_styles()
        self._refresh_theme_widgets()
        self.render_page()

    def _refresh_theme_widgets(self) -> None:
        c = self.colors
        self.theme_button.configure(text=self._theme_button_text())
        self.log_text.configure(bg=c["log"], fg=c["log_text"], insertbackground=c["text"],
                                selectbackground=c["accent"], selectforeground="#ffffff")
        self.log_text.tag_configure("ok", foreground=c["ok"])
        self.log_text.tag_configure("warning", foreground=c["warn"])
        self.log_text.tag_configure("error", foreground=c["error"])
        self.copyright_label.configure(foreground=c["muted"])
        self.status_label.configure(foreground=c.get(self.status_level, c["text"]))

    def _refresh_chrome(self) -> None:
        self.title(self.t("app_title"))
        self.title_label.configure(text=self.t("app_title"))
        self.about_button.configure(text=self.t("about"))
        self.theme_button.configure(text=self._theme_button_text())
        self.log_label.configure(text=self.t("operation_log"))
        self.copyright_label.configure(text=self.t("copyright"))
        self.cancel_button.configure(text=self.t("cancel"))
        self.back_button.configure(text=self.t("back"))
        self.next_button.configure(text=self.t("close") if self.step == len(self.STEP_KEYS) - 1 else self.t("next"))

    def _render_steps(self) -> None:
        for widget in self.step_bar.winfo_children():
            widget.destroy()
        for index, key in enumerate(self.STEP_KEYS):
            style = "Active.Step.TLabel" if index == self.step else ("Done.Step.TLabel" if index < self.step else "Step.TLabel")
            label = ttk.Label(self.step_bar, text=f"{index + 1}. {self.t(key)}", style=style, anchor="center")
            label.pack(side="left", fill="x", expand=True, padx=2)

    def render_page(self) -> None:
        for widget in self.page.winfo_children():
            widget.destroy()
        self._refresh_chrome()
        self._render_steps()
        self.back_button.configure(state="disabled" if self.step == 0 or self.busy else "normal")
        self.next_button.configure(state="disabled" if self.busy else "normal")
        renderers = (self._page_welcome, self._page_project, self._page_server,
                     self._page_diagnostics, self._page_database,
                     self._page_install, self._page_finish)
        renderers[self.step]()

    def _page_heading(self, title: str, body: str) -> None:
        ttk.Label(self.page, text=title, style="Title.TLabel").pack(anchor="w")
        ttk.Label(self.page, text=body, style="Subtitle.TLabel", wraplength=820, justify="left").pack(anchor="w", pady=(4, 10))

    def _page_welcome(self) -> None:
        self._page_heading(self.t("welcome"), self.t("welcome_body"))
        ttk.Label(self.page, text=self.t("choose_language"), foreground=GOLD, font=("Segoe UI", 12, "bold")).pack(anchor="w", pady=(8, 8))
        self.language_var = tk.StringVar(value=self.language)
        languages = ttk.Frame(self.page)
        languages.pack(anchor="w")
        for code, name in LANGUAGES.items():
            ttk.Radiobutton(languages, text=name, value=code, variable=self.language_var,
                            command=lambda value=code: self._set_language(value)).pack(side="left", padx=(0, 20))

    def _set_language(self, language: str) -> None:
        self.language = language
        self.render_page()

    def _page_project(self) -> None:
        self._page_heading(self.t("project"), self.t("project_body"))
        row = ttk.Frame(self.page)
        row.pack(fill="x", pady=10)
        self.project_var = tk.StringVar(value=str(self.core.project))
        ttk.Entry(row, textvariable=self.project_var).pack(side="left", fill="x", expand=True)
        ttk.Button(row, text=self.t("browse"), command=self._browse_project).pack(side="left", padx=(10, 0))

    def _browse_project(self) -> None:
        selected = filedialog.askdirectory(title=self.t("select_project"), initialdir=str(self.core.project), mustexist=True)
        if selected:
            self.project_var.set(selected)

    def _page_server(self) -> None:
        self._page_heading(self.t("server"), self.t("server_body"))
        self.server_public_var = tk.BooleanVar(value=self.server_config.public)
        self.server_debug_var = tk.BooleanVar(value=self.server_config.debug)
        visibility = ttk.Frame(self.page)
        visibility.pack(fill="x", pady=(0, 8))
        ttk.Label(visibility, text=self.t("visibility"), foreground=GOLD,
                  font=("Segoe UI", 10, "bold")).pack(side="left", padx=(0, 12))
        ttk.Radiobutton(visibility, text=self.t("private_project"), value=False,
                        variable=self.server_public_var, command=self._refresh_cef_preview).pack(side="left")
        ttk.Radiobutton(visibility, text=self.t("public_project"), value=True,
                        variable=self.server_public_var, command=self._refresh_cef_preview).pack(side="left", padx=12)
        ttk.Checkbutton(visibility, text=self.t("debug_mode"), variable=self.server_debug_var,
                        command=self._refresh_cef_preview).pack(side="left", padx=(18, 0))

        form = ttk.Frame(self.page)
        form.pack(fill="x")
        values = {
            "host_name": self.server_config.host_name,
            "max_slots": str(self.server_config.max_slots),
            "game_port": str(self.server_config.game_port),
            "master_url": self.server_config.master_url,
            "world": self.server_config.world,
            "web_source": self.server_config.web_source,
        }
        self.server_vars = {name: tk.StringVar(value=value) for name, value in values.items()}
        ttk.Label(form, text=self.t("server_name")).grid(row=0, column=0, sticky="w", pady=3)
        ttk.Entry(form, textvariable=self.server_vars["host_name"]).grid(row=0, column=1, sticky="ew", padx=(8, 18), pady=3)
        ttk.Label(form, text=self.t("max_slots")).grid(row=0, column=2, sticky="w", pady=3)
        ttk.Entry(form, textvariable=self.server_vars["max_slots"], width=9).grid(row=0, column=3, sticky="ew", padx=(8, 0), pady=3)
        ttk.Label(form, text=self.t("game_port")).grid(row=1, column=0, sticky="w", pady=3)
        ttk.Entry(form, textvariable=self.server_vars["game_port"]).grid(row=1, column=1, sticky="ew", padx=(8, 18), pady=3)
        ttk.Label(form, text=self.t("master_url")).grid(row=1, column=2, sticky="w", pady=3)
        ttk.Entry(form, textvariable=self.server_vars["master_url"]).grid(row=1, column=3, sticky="ew", padx=(8, 0), pady=3)
        ttk.Label(form, text=self.t("world_path")).grid(row=2, column=0, sticky="w", pady=3)
        ttk.Entry(form, textvariable=self.server_vars["world"]).grid(row=2, column=1, columnspan=3, sticky="ew", padx=(8, 0), pady=3)
        form.columnconfigure(1, weight=1)
        form.columnconfigure(3, weight=1)

        description_header = ttk.Frame(self.page)
        description_header.pack(fill="x", pady=(7, 3))
        ttk.Label(description_header, text=self.t("server_description")).pack(side="left")
        self.description_counter = ttk.Label(description_header, style="Subtitle.TLabel")
        self.description_counter.pack(side="right")

        toolbar = ttk.Frame(self.page)
        toolbar.pack(fill="x", pady=(0, 3))
        for label, opening, closing in (
                ("B", "<b>", "</b>"), ("I", "<i>", "</i>"), ("U", "<u>", "</u>"),
                (self.t("format_center"), "<center>", "</center>")):
            ttk.Button(toolbar, text=label, style="Tool.TButton",
                       command=lambda start=opening, end=closing: self._description_wrap(start, end)).pack(side="left", padx=(0, 4))
        ttk.Button(toolbar, text="BR", style="Tool.TButton", command=self._description_break).pack(side="left", padx=(0, 4))
        ttk.Button(toolbar, text=self.t("format_color"), style="Tool.TButton",
                   command=self._description_color).pack(side="left", padx=(0, 8))
        ttk.Label(toolbar, text=self.t("format_size")).pack(side="left")
        self.description_size_var = tk.StringVar(value="4")
        ttk.Combobox(toolbar, textvariable=self.description_size_var, values=tuple(str(value) for value in range(1, 8)),
                     state="readonly", width=3).pack(side="left", padx=4)
        ttk.Button(toolbar, text="OK", style="Tool.TButton",
                   command=self._description_size).pack(side="left")

        editors = ttk.Frame(self.page)
        editors.pack(fill="x")
        ttk.Label(editors, text=self.t("description_source"), style="Subtitle.TLabel").grid(row=0, column=0, sticky="w")
        ttk.Label(editors, text=self.t("description_preview"), style="Subtitle.TLabel").grid(row=0, column=1, sticky="w", padx=(12, 0))
        self.server_description = tk.Text(editors, height=5, relief="flat", borderwidth=1,
                                          bg=self.colors["field"], fg=self.colors["text"],
                                          insertbackground=self.colors["text"],
                                          selectbackground=self.colors["accent"], wrap="word",
                                          font=("Consolas", 9))
        self.server_description.grid(row=1, column=0, sticky="nsew")
        self.description_preview = tk.Text(editors, height=5, relief="flat", borderwidth=1,
                                           bg=self.colors["field"], fg=self.colors["text"], wrap="word",
                                           font=("Segoe UI", 10), state="disabled", cursor="arrow")
        self.description_preview.grid(row=1, column=1, sticky="nsew", padx=(12, 0))
        editors.columnconfigure(0, weight=1, uniform="description")
        editors.columnconfigure(1, weight=1, uniform="description")
        self.server_description.insert("1.0", self.server_config.description)
        self.server_description.edit_modified(False)
        self.server_description.bind("<<Modified>>", self._description_changed)
        self._render_description_preview()

        web_row = ttk.Frame(self.page)
        web_row.pack(fill="x", pady=(8, 3))
        ttk.Label(web_row, text=self.t("web_source")).pack(side="left")
        ttk.Entry(web_row, textvariable=self.server_vars["web_source"]).pack(side="left", fill="x", expand=True, padx=8)
        ttk.Button(web_row, text=self.t("browse"), command=self._browse_web_source).pack(side="right")
        self.cef_preview = ttk.Label(self.page, style="Subtitle.TLabel")
        self.cef_preview.pack(anchor="w", pady=(2, 5))
        ttk.Button(self.page, text=self.t("save_server"), style="Accent.TButton",
                   command=self._save_server_form).pack(anchor="e")
        self._refresh_cef_preview()

    def _description_wrap(self, opening: str, closing: str) -> None:
        try:
            start, end = self.server_description.index("sel.first"), self.server_description.index("sel.last")
            selected = self.server_description.get(start, end)
            self.server_description.delete(start, end)
            self.server_description.insert(start, opening + selected + closing)
        except tk.TclError:
            position = self.server_description.index("insert")
            self.server_description.insert(position, opening + closing)
            self.server_description.mark_set("insert", f"{position}+{len(opening)}c")
        self.server_description.focus_set()

    def _description_break(self) -> None:
        self.server_description.insert("insert", "<br>")
        self.server_description.focus_set()

    def _description_color(self) -> None:
        color = simpledialog.askstring(self.t("format_color"), self.t("color_prompt"),
                                       initialvalue="White", parent=self)
        if not color:
            return
        try:
            self.winfo_rgb(color.strip())
        except tk.TclError:
            messagebox.showerror(self.t("validation_error"), self.t("invalid_description"), parent=self)
            return
        self._description_wrap(f'<font color="{color.strip()}">', "</font>")

    def _description_size(self) -> None:
        self._description_wrap(f'<font size="{self.description_size_var.get()}">', "</font>")

    def _description_changed(self, _event: tk.Event[tk.Misc] | None = None) -> None:
        if not self.server_description.edit_modified():
            return
        self.server_description.edit_modified(False)
        self._render_description_preview()

    def _render_description_preview(self) -> None:
        from html.parser import HTMLParser

        raw = self.server_description.get("1.0", "end-1c")
        limit = ServerConfig.description_max_length
        count = len(raw)
        self.description_counter.configure(
            text=self.t("description_counter", count=count, limit=limit),
            foreground=self.colors["error"] if count > limit else self.colors["muted"])
        preview = self.description_preview
        preview.configure(state="normal")
        preview.delete("1.0", "end")
        preview.tag_configure("bold", font=("Segoe UI", 10, "bold"))
        preview.tag_configure("italic", font=("Segoe UI", 10, "italic"))
        preview.tag_configure("bold_italic", font=("Segoe UI", 10, "bold italic"))
        preview.tag_configure("underline", underline=True)
        preview.tag_configure("center", justify="center")
        sizes = {1: 7, 2: 8, 3: 9, 4: 10, 5: 12, 6: 15, 7: 18}
        for html_size, points in sizes.items():
            preview.tag_configure(f"size_{html_size}", font=("Segoe UI", points))

        class PreviewParser(HTMLParser):
            def __init__(self) -> None:
                super().__init__(convert_charrefs=True)
                self.bold = self.italic = self.underline = self.center = 0
                self.fonts: list[dict[str, str]] = []
                self.color_index = 0

            def handle_starttag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
                tag = tag.lower()
                if tag in {"b", "strong"}:
                    self.bold += 1
                elif tag in {"i", "em"}:
                    self.italic += 1
                elif tag == "u":
                    self.underline += 1
                elif tag == "center":
                    self.center += 1
                elif tag == "font":
                    self.fonts.append({key.lower(): value or "" for key, value in attrs})
                elif tag == "br":
                    preview.insert("end", "\n", self._tags())
                elif tag in {"p", "div"} and preview.index("end-1c") != "1.0":
                    preview.insert("end", "\n", self._tags())

            def handle_startendtag(self, tag: str, attrs: list[tuple[str, str | None]]) -> None:
                self.handle_starttag(tag, attrs)

            def handle_endtag(self, tag: str) -> None:
                tag = tag.lower()
                if tag in {"b", "strong"}:
                    self.bold = max(0, self.bold - 1)
                elif tag in {"i", "em"}:
                    self.italic = max(0, self.italic - 1)
                elif tag == "u":
                    self.underline = max(0, self.underline - 1)
                elif tag == "center":
                    self.center = max(0, self.center - 1)
                elif tag == "font" and self.fonts:
                    self.fonts.pop()
                elif tag in {"p", "div"}:
                    preview.insert("end", "\n", self._tags())

            def _tags(self) -> tuple[str, ...]:
                tags: list[str] = []
                if self.bold and self.italic:
                    tags.append("bold_italic")
                elif self.bold:
                    tags.append("bold")
                elif self.italic:
                    tags.append("italic")
                if self.underline:
                    tags.append("underline")
                if self.center:
                    tags.append("center")
                if self.fonts:
                    size = self.fonts[-1].get("size", "")
                    if size.isdigit() and 1 <= int(size) <= 7:
                        tags.append(f"size_{size}")
                    color = self.fonts[-1].get("color", "").strip()
                    if color:
                        try:
                            preview.winfo_rgb(color)
                            color_tag = f"color_{self.color_index}"
                            self.color_index += 1
                            preview.tag_configure(color_tag, foreground=color)
                            tags.append(color_tag)
                        except tk.TclError:
                            pass
                return tuple(tags)

            def handle_data(self, data: str) -> None:
                preview.insert("end", data, self._tags())

        try:
            PreviewParser().feed(raw)
        except (ValueError, tk.TclError):
            preview.delete("1.0", "end")
            preview.insert("1.0", raw)
        preview.configure(state="disabled")

    def _refresh_cef_preview(self) -> None:
        if not hasattr(self, "cef_preview"):
            return
        packed = self.server_public_var.get()
        if packed:
            text = self.t("cef_package_mode", url="cef://index.html")
        else:
            source = self.server_vars["web_source"].get() if hasattr(self, "server_vars") else self.server_config.web_source
            text = self.t("cef_file_mode", url=str((self.core.project / source / "index.html").resolve()))
        self.cef_preview.configure(text=text)

    def _browse_web_source(self) -> None:
        initial = (self.core.project / self.server_vars["web_source"].get()).resolve()
        selected = filedialog.askdirectory(title=self.t("web_source"), initialdir=str(initial), mustexist=True)
        if not selected:
            return
        try:
            relative = Path(selected).resolve().relative_to(self.core.project.resolve())
        except ValueError:
            messagebox.showerror(self.t("validation_error"), self.t("invalid_web_source"), parent=self)
            return
        self.server_vars["web_source"].set(relative.as_posix())
        self._refresh_cef_preview()

    def _read_server_form(self) -> ServerConfig | None:
        try:
            config = ServerConfig(
                public=self.server_public_var.get(), debug=self.server_debug_var.get(),
                host_name=self.server_vars["host_name"].get().strip(),
                description=self.server_description.get("1.0", "end-1c").strip(),
                max_slots=int(self.server_vars["max_slots"].get().strip()),
                game_port=int(self.server_vars["game_port"].get().strip()),
                master_url=self.server_vars["master_url"].get().strip(),
                world=self.server_vars["world"].get().strip(),
                web_source=self.server_vars["web_source"].get().strip().replace("\\", "/"),
                addon_path=self.server_config.addon_path,
            )
        except ValueError:
            messagebox.showerror(self.t("validation_error"), self.t("invalid_server_numbers"), parent=self)
            return None
        problem = validate_server_config(self.core.project, config)
        if problem:
            messagebox.showerror(self.t("validation_error"), self.t(problem), parent=self)
            return None
        return config

    def _save_server_form(self, show_confirmation: bool = True) -> bool:
        config = self._read_server_form()
        if not config:
            return False
        try:
            _backups, archive = save_server_config(self.core.project, config)
        except (OSError, PermissionError, ValueError) as error:
            key = str(error) if str(error) else "config_structure_invalid"
            self._show_error(self.t(key) if key.startswith("invalid_") or key in {
                "config_structure_invalid", "web_archive_invalid"
            } else key)
            return False
        self.server_config = config
        message = self.t("server_saved")
        if archive:
            message += " " + self.t("web_package_built", path=archive)
        self._log(message, "ok")
        self._set_status(message, "ok")
        self.diagnostic_items = []
        if show_confirmation:
            messagebox.showinfo(self.t("app_title"), message, parent=self)
        return True

    def _page_diagnostics(self) -> None:
        self._page_heading(self.t("diagnostics"), self.t("diagnostics_body"))
        self.diag_tree = ttk.Treeview(self.page, show="tree", selectmode="none", height=12)
        self.diag_tree.pack(fill="both", expand=True)
        self.diag_tree.tag_configure("ok", foreground=OK)
        self.diag_tree.tag_configure("warning", foreground=WARN)
        self.diag_tree.tag_configure("error", foreground=ERROR)
        buttons = ttk.Frame(self.page)
        buttons.pack(fill="x", pady=(12, 0))
        ttk.Button(buttons, text=self.t("rerun"), command=self.run_diagnostics).pack(side="left")
        self._show_diagnostics()
        if not self.diagnostic_items and not self.busy:
            self.after(50, self.run_diagnostics)

    def _show_diagnostics(self) -> None:
        if not hasattr(self, "diag_tree"):
            return
        for child in self.diag_tree.get_children():
            self.diag_tree.delete(child)
        labels = {"ok": self.t("status_ok"), "warning": self.t("status_warning"), "error": self.t("status_error")}
        for item in self.diagnostic_items:
            message = self.t(item.key, **item.values)
            if item.key == "status_ok" and item.values.get("item"):
                message = f"{item.values['item']}: {self.t('status_ok')}"
            self.diag_tree.insert("", "end", text=f"[{labels[item.level]}]  {message}", tags=(item.level,))
        blocked = any(item.level == "error" for item in self.diagnostic_items)
        self.next_button.configure(state="disabled" if blocked or self.busy or not self.diagnostic_items else "normal")

    def _page_database(self) -> None:
        self._page_heading(self.t("database"), self.t("database_body"))
        values = {
            "host": self.db_config.host, "port": str(self.db_config.port), "user": self.db_config.user,
            "password": self.db_config.password, "database": self.db_config.database,
            "encoding": self.db_config.encoding, "root_password": self.db_config.root_password,
        }
        labels = (("host", "db_host"), ("port", "db_port"), ("user", "db_user"),
                  ("password", "db_password"), ("database", "db_name"),
                  ("encoding", "db_encoding"), ("root_password", "db_root_password"))
        form = ttk.Frame(self.page)
        form.pack(fill="x")
        self.db_vars: dict[str, tk.StringVar] = {}
        for row, (name, label_key) in enumerate(labels):
            ttk.Label(form, text=self.t(label_key)).grid(row=row, column=0, sticky="w", padx=(0, 16), pady=5)
            variable = tk.StringVar(value=values[name])
            self.db_vars[name] = variable
            entry = ttk.Entry(form, textvariable=variable, show="•" if "password" in name else "")
            entry.grid(row=row, column=1, sticky="ew", pady=5)
        form.columnconfigure(1, weight=1)
        actions = ttk.Frame(self.page)
        actions.pack(fill="x", pady=(16, 0))
        ttk.Button(actions, text=self.t("generate"), command=self._generate_passwords).pack(side="left")
        ttk.Button(actions, text=self.t("save_config"), style="Accent.TButton", command=self._save_database_form).pack(side="left", padx=8)

    def _generate_passwords(self) -> None:
        self.db_vars["password"].set(generate_password())
        self.db_vars["root_password"].set(generate_password())

    def _read_database_form(self) -> DBConfig | None:
        try:
            config = DBConfig(
                host=self.db_vars["host"].get().strip(), port=int(self.db_vars["port"].get().strip()),
                user=self.db_vars["user"].get().strip(), password=self.db_vars["password"].get(),
                database=self.db_vars["database"].get().strip(), encoding=self.db_vars["encoding"].get().strip(),
                root_password=self.db_vars["root_password"].get(),
            )
        except ValueError:
            messagebox.showerror(self.t("validation_error"), self.t("invalid_port"), parent=self)
            return None
        problem = validate_db_config(config)
        if problem:
            messagebox.showerror(self.t("validation_error"), self.t(problem), parent=self)
            return None
        return config

    def _save_database_form(self) -> bool:
        config = self._read_database_form()
        if not config:
            return False
        try:
            save_db_config(self.core.project, config)
        except (OSError, PermissionError) as error:
            self._show_error(str(error))
            return False
        self.db_config = config
        self._log(self.t("config_saved"), "ok")
        self._set_status(self.t("config_saved"), "ok")
        return True

    def _page_install(self) -> None:
        self._page_heading(self.t("install"), self.t("install_body"))
        docker_row = ttk.Frame(self.page)
        docker_row.pack(fill="x", pady=(0, 14))
        ttk.Button(docker_row, text=self.t("install_docker"), command=self._install_docker).pack(side="left")
        ttk.Button(docker_row, text=self.t("build_web"), command=self._build_web_package).pack(side="left", padx=8)
        if self.core.system == "Linux":
            ttk.Button(docker_row, text=self.t("docker_group"), command=self._add_docker_group).pack(side="left", padx=8)
        self._management_buttons(self.page)

    def _build_web_package(self) -> None:
        try:
            archive = build_web_archive(self.core.project, self.server_config)
        except (OSError, PermissionError, ValueError) as error:
            key = str(error) or "web_archive_invalid"
            self._show_error(self.t(key) if key in {
                "invalid_web_source", "invalid_addon_path", "web_archive_invalid"
            } else key)
            return
        message = self.t("web_package_built", path=archive)
        self._log(message, "ok")
        self._set_status(message, "ok")

    def _management_buttons(self, parent: ttk.Frame) -> None:
        grid = ttk.Frame(parent)
        grid.pack(fill="x", pady=8)
        actions: tuple[tuple[str, Callable[[], None], str], ...] = (
            ("start_db", self._start_db, "Accent.TButton"), ("stop_db", self._stop_db, "TButton"),
            ("db_status", self._db_status, "TButton"), ("db_logs", self._db_logs, "TButton"),
            ("health", self._health, "TButton"), ("start_server", self._start_server, "Accent.TButton"),
            ("reset_db", self._reset_database, "Danger.TButton"),
        )
        for index, (key, command, style) in enumerate(actions):
            ttk.Button(grid, text=self.t(key), command=command, style=style).grid(
                row=index // 4, column=index % 4, sticky="ew", padx=4, pady=4)
        for column in range(4):
            grid.columnconfigure(column, weight=1)

    def _page_finish(self) -> None:
        self._page_heading(self.t("finish"), self.t("finish_body"))
        mode = self.t("mode_public") if self.server_config.public else self.t("mode_private")
        debug = self.t("debug_enabled") if self.server_config.debug else self.t("debug_disabled")
        report = "\n".join((self.t("report"), self.t("report_project", path=self.core.project),
                             self.t("report_server", name=self.server_config.host_name,
                                    port=self.server_config.game_port, slots=self.server_config.max_slots),
                             self.t("report_mode", mode=mode, debug=debug,
                                    cef=self.server_config.cef_url(self.core.project)),
                             self.t("report_db", host=self.db_config.host, port=self.db_config.port,
                                    name=self.db_config.database), self.t("report_privacy")))
        label = tk.Label(self.page, text=report, bg=PANEL, fg=TEXT, justify="left", anchor="nw",
                         font=("Segoe UI", 11), padx=18, pady=16)
        label.pack(fill="x", pady=(0, 10))
        self._management_buttons(self.page)

    def next_step(self) -> None:
        if self.busy:
            return
        if self.step == len(self.STEP_KEYS) - 1:
            self._request_close(force=True)
            return
        if self.step == 1:
            path = Path(self.project_var.get()).expanduser()
            if not path.is_dir():
                messagebox.showerror(self.t("app_title"), self.t("invalid_project"), parent=self)
                return
            self.core.set_project(path)
            self.db_config = load_db_config(path)
            self.server_config = load_server_config(path)
            self.diagnostic_items = []
        elif self.step == 2 and not self._save_server_form(show_confirmation=False):
            return
        elif self.step == 3 and any(item.level == "error" for item in self.diagnostic_items):
            return
        elif self.step == 4 and not self._save_database_form():
            return
        self.step += 1
        self.render_page()

    def previous_step(self) -> None:
        if not self.busy and self.step > 0:
            self.step -= 1
            self.render_page()

    def run_diagnostics(self) -> None:
        self.run_async(lambda: self.core.diagnostics(self.server_config), self._diagnostics_done)

    def _diagnostics_done(self, items: list[DiagnosticItem]) -> None:
        self.diagnostic_items = items
        self._show_diagnostics()
        for item in items:
            self._log(self.t(item.key, **item.values), item.level)

    def _walk(self, widget: tk.Misc) -> list[tk.Misc]:
        result: list[tk.Misc] = []
        for child in widget.winfo_children():
            result.append(child)
            result.extend(self._walk(child))
        return result

    def _set_busy(self, busy: bool) -> None:
        self.busy = busy
        self._set_status(self.t("working") if busy else self.t("ready"), "warning" if busy else "ok")
        for widget in self._walk(self.page):
            if isinstance(widget, ttk.Button):
                widget.configure(state="disabled" if busy else "normal")
        self.back_button.configure(state="disabled" if busy or self.step == 0 else "normal")
        self.next_button.configure(state="disabled" if busy else "normal")
        if not busy and self.step == 3:
            self._show_diagnostics()

    def run_async(self, operation: Callable[[], Any], callback: Callable[[Any], None] | None = None) -> None:
        if self.busy:
            return
        self._set_busy(True)

        def worker() -> None:
            try:
                result = operation()
                self.events.put(("done", (callback, result)))
            except (FileNotFoundError, PermissionError, OSError, RuntimeError, ValueError) as error:
                self.events.put(("error", error))
            except Exception as error:  # Keep the GUI alive on unexpected platform failures.
                self.events.put(("error", error))

        threading.Thread(target=worker, daemon=True, name="phoenix-worker").start()

    def _drain_events(self) -> None:
        try:
            while True:
                kind, payload = self.events.get_nowait()
                if kind == "done":
                    callback, result = payload
                    self._set_busy(False)
                    if callback:
                        callback(result)
                elif kind == "error":
                    self._set_busy(False)
                    self._show_error(str(payload))
        except queue.Empty:
            pass
        if not self.closed:
            self.after(100, self._drain_events)

    def _scrub(self, text: str) -> str:
        for secret in (self.db_config.password, self.db_config.root_password):
            if secret:
                text = text.replace(secret, "***")
        return text

    def _log(self, message: str, level: str = "ok") -> None:
        if self.closed:
            return
        clean = self._scrub(message).strip()
        if not clean:
            return
        self.log_text.configure(state="normal")
        self.log_text.tag_configure("ok", foreground=OK)
        self.log_text.tag_configure("warning", foreground=WARN)
        self.log_text.tag_configure("error", foreground=ERROR)
        self.log_text.insert("end", clean + "\n", level)
        self.log_text.see("end")
        self.log_text.configure(state="disabled")

    def _set_status(self, text: str, level: str) -> None:
        self.status_level = level
        color = {"ok": OK, "warning": WARN, "error": ERROR}.get(level, TEXT)
        self.status_label.configure(text=text, foreground=color)

    def _show_error(self, error: str) -> None:
        message = self.t("operation_failed", error=self._scrub(error))
        self._log(message, "error")
        self._set_status(message, "error")
        messagebox.showerror(self.t("app_title"), message, parent=self)

    def _command_done(self, result: Any) -> None:
        stdout = getattr(result, "stdout", "").strip()
        stderr = getattr(result, "stderr", "").strip()
        output = "\n".join(value for value in (stdout, stderr) if value)
        if output:
            self._log(output, "ok" if result.ok else "error")
        if result.ok:
            self._set_status(self.t("ready"), "ok")
            return
        detail = stderr or stdout or f"exit code {getattr(result, 'returncode', '?')}"
        message = self.t("operation_failed", error=self._scrub(detail))
        self._set_status(message, "error")
        messagebox.showerror(self.t("app_title"), message, parent=self)

    def _start_db(self) -> None:
        def start_and_verify() -> tuple[Any, bool]:
            result = self.core.start_database()
            healthy = result.ok and self.core.wait_for_health(self.db_config.port, 180)
            return result, healthy

        self.run_async(start_and_verify, self._start_db_done)

    def _start_db_done(self, outcome: tuple[Any, bool]) -> None:
        result, healthy = outcome
        self._command_done(result)
        if result.ok:
            self._health_done(healthy)

    def _stop_db(self) -> None:
        self.run_async(self.core.stop_database, self._command_done)

    def _db_status(self) -> None:
        self.run_async(self.core.database_status, self._command_done)

    def _db_logs(self) -> None:
        self.run_async(self.core.database_logs, self._command_done)

    def _health(self) -> None:
        self.run_async(lambda: self.core.wait_for_health(self.db_config.port, 120), self._health_done)

    def _health_done(self, healthy: bool) -> None:
        key = "db_healthy" if healthy else "db_unhealthy"
        level = "ok" if healthy else "error"
        self._log(self.t(key), level)
        self._set_status(self.t(key), level)
        if not healthy:
            messagebox.showwarning(self.t("app_title"), self.t(key), parent=self)

    def _start_server(self) -> None:
        self.run_async(self.core.launch_server, self._server_done)

    def _server_done(self, result: tuple[bool, str]) -> None:
        success, detail = result
        message = self.t(detail) if detail in {"server_started", "native_missing"} else detail
        level = "ok" if success else "warning"
        self._log(message, level)
        self._set_status(message, level)
        if not success:
            messagebox.showwarning(self.t("app_title"), message, parent=self)

    def _install_docker(self) -> None:
        try:
            commands = self.core.docker_install_commands()
        except PermissionError as error:
            self._show_error(str(error))
            return
        if not commands:
            if self.core.system == "Windows":
                self.core.open_docker_website()
                messagebox.showinfo(self.t("app_title"), self.t("winget_missing"), parent=self)
            else:
                self._show_error(self.t("compose_unavailable"))
            return
        shown = "\n".join(format_command(command) for command in commands)
        if not messagebox.askyesno(self.t("install_docker"), self.t("docker_confirm", command=shown), parent=self):
            return
        self._log(self.t("command_shown", command=shown), "warning")
        self.run_async(lambda: self.core.install_docker(commands), self._docker_install_done)

    def _docker_install_done(self, result: Any) -> None:
        self._command_done(result)
        if result.ok and self.core.system == "Windows":
            messagebox.showinfo(self.t("install_docker"), self.t("docker_desktop_note"), parent=self)

    def _add_docker_group(self) -> None:
        try:
            command = self.core.docker_group_command()
        except PermissionError as error:
            self._show_error(str(error))
            return
        if not command:
            self._show_error(self.t("compose_unavailable"))
            return
        shown = format_command(command)
        if not messagebox.askyesno(self.t("docker_group"), self.t("group_confirm", command=shown), parent=self):
            return
        self._log(self.t("command_shown", command=shown), "warning")
        self.run_async(lambda: self.core.add_user_to_docker_group(command), self._command_done)

    def _reset_database(self) -> None:
        backup = messagebox.askyesnocancel(self.t("reset_title"), self.t("backup_question"), parent=self)
        if backup is None:
            return
        if backup:
            self.run_async(lambda: self.core.create_backup(self.db_config), self._backup_done)
        else:
            self._confirm_reset()

    def _backup_done(self, result: tuple[bool, Path | None, str]) -> None:
        success, path, error = result
        if not success:
            self._log(self.t("backup_failed"), "error")
            messagebox.showerror(self.t("reset_title"), self.t("backup_failed") + (f"\n{self._scrub(error)}" if error else ""), parent=self)
            return
        self._log(self.t("backup_done", path=path), "ok")
        self._confirm_reset()

    def _confirm_reset(self) -> None:
        typed = simpledialog.askstring(self.t("reset_title"), self.t("type_db_name", name=self.db_config.database), parent=self)
        if typed is None:
            return
        if typed != self.db_config.database:
            messagebox.showwarning(self.t("reset_title"), self.t("name_not_match"), parent=self)
            return
        if not messagebox.askyesno(self.t("reset_title"), self.t("reset_confirm"), icon="warning", parent=self):
            return
        self.run_async(
            lambda: self.core.preflight_database_reset(self.db_config.port),
            self._reset_preflight_done,
        )

    def _reset_preflight_done(self, result: DatabaseResetPreflight) -> None:
        if result.safe:
            self._run_confirmed_reset()
            return
        if result.error:
            self._show_error(result.error)
            return
        conflict = result.conflict
        if conflict is None:
            self._show_error(self.t("reset_preflight_failed"))
            return
        if conflict.kind != "docker":
            messagebox.showerror(
                self.t("reset_title"),
                self.t("reset_host_conflict", port=conflict.port),
                parent=self,
            )
            return
        approved = messagebox.askyesno(
            self.t("reset_title"),
            self.t(
                "reset_foreign_container",
                port=conflict.port,
                owner=conflict.display_name,
                container=conflict.container_id[:12],
            ),
            icon="warning",
            parent=self,
        )
        if not approved:
            self._log(self.t("reset_cancelled"), "warn")
            self._set_status(self.t("reset_cancelled"), "warn")
            return
        self.run_async(
            lambda: self.core.stop_conflicting_container(conflict),
            self._conflicting_container_stopped,
        )

    def _conflicting_container_stopped(self, result: tuple[bool, str]) -> None:
        success, error = result
        if not success:
            self._show_error(self.t("reset_stop_failed", error=self._scrub(error)))
            return
        self._run_confirmed_reset()

    def _run_confirmed_reset(self) -> None:
        self.run_async(lambda: self.core.reset_database(self.db_config.port), self._reset_done)

    def _reset_done(self, result: tuple[bool, str]) -> None:
        success, error = result
        if success:
            self._log(self.t("reset_done"), "ok")
            self._set_status(self.t("reset_done"), "ok")
        else:
            self._show_error(error)

    def _show_about(self) -> None:
        messagebox.showinfo(self.t("about"), self.t("about_text"), parent=self)

    def _request_close(self, force: bool = False) -> None:
        if force or messagebox.askyesno(self.t("cancel"), self.t("cancel_confirm"), parent=self):
            self.closed = True
            self.destroy()


def main() -> None:
    PhoenixInstaller().mainloop()
