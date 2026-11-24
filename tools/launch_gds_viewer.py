#!/usr/bin/env python3

import os
import sys
import tkinter as tk
from tkinter import ttk, messagebox
from PIL import Image, ImageTk

class GDSViewer(tk.Tk):
    def __init__(self, gds_img_path, zoom_img_path):
        super().__init__()
        self.title("ASIC GDSII Layout Viewer — 8-Bit Pipelined RISC Microprocessor (Nangate 45nm)")
        self.geometry("1150x820")
        self.minsize(900, 650)
        self.configure(bg="#0F172A")

        self.gds_img_path = gds_img_path
        self.zoom_img_path = zoom_img_path
        self.current_mode = "full"

        self.orig_image = Image.open(self.gds_img_path)
        self.zoom_image = Image.open(self.zoom_img_path) if os.path.exists(self.zoom_img_path) else self.orig_image

        self.scale = 1.0
        self.pan_x = 0
        self.pan_y = 0
        self.drag_start = None

        self._build_ui()
        self._load_and_draw()

    def _build_ui(self):
        toolbar = tk.Frame(self, bg="#1E293B", height=50)
        toolbar.pack(side=tk.TOP, fill=tk.X, padx=8, pady=6)

        lbl_title = tk.Label(toolbar, text="GDSII Core: top (160×160 µm)", font=("Segoe UI", 12, "bold"), fg="#38BDF8", bg="#1E293B")
        lbl_title.pack(side=tk.LEFT, padx=12)

        btn_full = tk.Button(toolbar, text="Full Die View", command=self.set_full_mode, bg="#334155", fg="#F8FAFC", font=("Segoe UI", 9, "bold"), relief="flat", padx=8, pady=3)
        btn_full.pack(side=tk.LEFT, padx=4)

        btn_macro = tk.Button(toolbar, text="Silicon Micro-Zoom", command=self.set_zoom_mode, bg="#334155", fg="#F8FAFC", font=("Segoe UI", 9, "bold"), relief="flat", padx=8, pady=3)
        btn_macro.pack(side=tk.LEFT, padx=4)

        btn_zin = tk.Button(toolbar, text="Zoom In (+)", command=self.zoom_in, bg="#2563EB", fg="#FFFFFF", font=("Segoe UI", 9, "bold"), relief="flat", padx=8, pady=3)
        btn_zin.pack(side=tk.LEFT, padx=6)

        btn_zout = tk.Button(toolbar, text="Zoom Out (-)", command=self.zoom_out, bg="#2563EB", fg="#FFFFFF", font=("Segoe UI", 9, "bold"), relief="flat", padx=8, pady=3)
        btn_zout.pack(side=tk.LEFT, padx=2)

        btn_fit = tk.Button(toolbar, text="Reset View", command=self.reset_view, bg="#475569", fg="#FFFFFF", font=("Segoe UI", 9), relief="flat", padx=8, pady=3)
        btn_fit.pack(side=tk.LEFT, padx=6)

        btn_schem = tk.Button(toolbar, text="Open Schematics", command=self.open_schematics_folder, bg="#059669", fg="#FFFFFF", font=("Segoe UI", 9, "bold"), relief="flat", padx=8, pady=3)
        btn_schem.pack(side=tk.RIGHT, padx=12)

        btn_gds_file = tk.Button(toolbar, text="Open GDS2 File", command=self.open_gds_external, bg="#D97706", fg="#FFFFFF", font=("Segoe UI", 9, "bold"), relief="flat", padx=8, pady=3)
        btn_gds_file.pack(side=tk.RIGHT, padx=4)

        main_pane = tk.Frame(self, bg="#0F172A")
        main_pane.pack(side=tk.TOP, fill=tk.BOTH, expand=True, padx=8, pady=4)

        canvas_frame = tk.Frame(main_pane, bg="#000000", bd=2, relief="sunken")
        canvas_frame.pack(side=tk.LEFT, fill=tk.BOTH, expand=True)

        self.canvas = tk.Canvas(canvas_frame, bg="#000000", highlightthickness=0)
        self.canvas.pack(fill=tk.BOTH, expand=True)

        self.canvas.bind("<ButtonPress-1>", self._on_pan_start)
        self.canvas.bind("<B1-Motion>", self._on_pan_drag)
        self.canvas.bind("<MouseWheel>", self._on_mousewheel)
        self.canvas.bind("<Motion>", self._on_mouse_move)

        sidebar = tk.Frame(main_pane, bg="#1E293B", width=280)
        sidebar.pack(side=tk.RIGHT, fill=tk.Y, padx=(8, 0))

        tk.Label(sidebar, text="PHYSICAL DESIGN SPECS", font=("Segoe UI", 10, "bold"), fg="#F8FAFC", bg="#1E293B").pack(anchor="w", padx=12, pady=(12, 6))

        specs = [
            ("Process Node", "Nangate 45nm Metal-Gate"),
            ("Die Dimensions", "160.0 µm × 160.0 µm"),
            ("Die Area", "0.0256 mm²"),
            ("Core Area", "140.0 µm × 140.0 µm"),
            ("Standard Cells", "3,503 Placed Cells"),
            ("Sequential DFFs", "1,103 Flip-Flops"),
            ("Supply Voltage", "1.10 V (Nominal)"),
            ("Target Frequency", "200.0 MHz"),
            ("Clock Period", "5.00 ns"),
            ("Power (Dynamic)", "1.40 mW"),
            ("Power Grid", "Metal 1 / Metal 4 Mesh")
        ]
        for key, val in specs:
            f = tk.Frame(sidebar, bg="#1E293B")
            f.pack(fill=tk.X, padx=12, pady=2)
            tk.Label(f, text=f"{key}:", font=("Segoe UI", 8, "bold"), fg="#94A3B8", bg="#1E293B").pack(side=tk.LEFT)
            tk.Label(f, text=val, font=("Segoe UI", 8), fg="#38BDF8" if "200" in val or "3,503" in val else "#F1F5F9", bg="#1E293B").pack(side=tk.RIGHT)

        tk.Label(sidebar, text="SILICON LAYERS & LEGEND", font=("Segoe UI", 10, "bold"), fg="#F8FAFC", bg="#1E293B").pack(anchor="w", padx=12, pady=(16, 6))

        layers = [
            ("Sequential Cells (DFF Array)", "#805AD5"),
            ("Combinational Gates (ALU/Logic)", "#3182CE"),
            ("Metal 4 PDN Mesh (VDD/VSS)", "#10B981"),
            ("I/O Bond Pads & Pins", "#FCD34D"),
            ("Active / Oxide (Diffusion)", "#F97316"),
            ("Polysilicon Gates", "#EF4444"),
            ("Metal 1 Interconnect Rails", "#38BDF8")
        ]
        for name, col in layers:
            f = tk.Frame(sidebar, bg="#1E293B")
            f.pack(fill=tk.X, padx=12, pady=3)
            box = tk.Label(f, text="   ", bg=col, relief="flat", width=2)
            box.pack(side=tk.LEFT, padx=(0, 6))
            tk.Label(f, text=name, font=("Segoe UI", 8), fg="#E2E8F0", bg="#1E293B").pack(side=tk.LEFT)

        self.status_bar = tk.Frame(self, bg="#0F172A", height=24)
        self.status_bar.pack(side=tk.BOTTOM, fill=tk.X, padx=8, pady=3)

        self.coord_lbl = tk.Label(self.status_bar, text="Cursor: X = 80.00 µm, Y = 80.00 µm | Zoom: 100%", font=("Consolas", 9), fg="#38BDF8", bg="#0F172A")
        self.coord_lbl.pack(side=tk.LEFT)

        hint_lbl = tk.Label(self.status_bar, text="Tip: Click & Drag to Pan | Scroll to Zoom | Mode buttons to switch view", font=("Segoe UI", 8, "italic"), fg="#64748B", bg="#0F172A")
        hint_lbl.pack(side=tk.RIGHT)

    def set_full_mode(self):
        self.current_mode = "full"
        self.reset_view()

    def set_zoom_mode(self):
        self.current_mode = "zoom"
        self.reset_view()

    def _get_active_image(self):
        return self.orig_image if self.current_mode == "full" else self.zoom_image

    def reset_view(self):
        self.scale = 1.0
        self.pan_x = 0
        self.pan_y = 0
        self._load_and_draw()

    def zoom_in(self):
        self.scale = min(self.scale * 1.25, 8.0)
        self._load_and_draw()

    def zoom_out(self):
        self.scale = max(self.scale / 1.25, 0.4)
        self._load_and_draw()

    def _on_mousewheel(self, event):
        if event.delta > 0:
            self.zoom_in()
        else:
            self.zoom_out()

    def _on_pan_start(self, event):
        self.drag_start = (event.x, event.y)

    def _on_pan_drag(self, event):
        if self.drag_start:
            dx = event.x - self.drag_start[0]
            dy = event.y - self.drag_start[1]
            self.pan_x += dx
            self.pan_y += dy
            self.drag_start = (event.x, event.y)
            self._load_and_draw()

    def _on_mouse_move(self, event):
        cw = self.canvas.winfo_width()
        ch = self.canvas.winfo_height()
        if cw > 0 and ch > 0:
            norm_x = (event.x - self.pan_x) / (cw * self.scale)
            norm_y = 1.0 - ((event.y - self.pan_y) / (ch * self.scale))
            if self.current_mode == "full":
                um_x = max(0.0, min(160.0, norm_x * 160.0))
                um_y = max(0.0, min(160.0, norm_y * 160.0))
            else:
                um_x = 40.0 + max(0.0, min(30.0, norm_x * 30.0))
                um_y = 40.0 + max(0.0, min(18.0, norm_y * 18.0))
            self.coord_lbl.config(text=f"Cursor: X = {um_x:.2f} µm, Y = {um_y:.2f} µm | Zoom: {int(self.scale * 100)}%")

    def _load_and_draw(self):
        img_src = self._get_active_image()
        cw = max(self.canvas.winfo_width(), 700)
        ch = max(self.canvas.winfo_height(), 600)

        target_w = int(cw * self.scale)
        target_h = int(ch * self.scale)
        if target_w < 50 or target_h < 50:
            return

        resized = img_src.resize((target_w, target_h), Image.Resampling.LANCZOS)
        self.tk_img = ImageTk.PhotoImage(resized)
        self.canvas.delete("all")
        cx = cw // 2 + self.pan_x
        cy = ch // 2 + self.pan_y
        self.canvas.create_image(cx, cy, image=self.tk_img)

    def open_schematics_folder(self):
        cur_dir = os.path.dirname(os.path.abspath(__file__))
        for p in [os.path.join(cur_dir, "..", "results", "schematics"),
                  os.path.join(cur_dir, "schematics"),
                  os.path.join(cur_dir, "..", "schematics")]:
            if os.path.exists(p):
                os.startfile(os.path.abspath(p))
                return
        messagebox.showinfo("Schematics", "Schematics directory not found.")

    def open_gds_external(self):
        cur_dir = os.path.dirname(os.path.abspath(__file__))
        for p in [os.path.join(cur_dir, "..", "synth", "top_pipelined_cpu.gds"),
                  os.path.join(cur_dir, "top_pipelined_cpu.gds"),
                  os.path.join(cur_dir, "..", "top_pipelined_cpu.gds")]:
            if os.path.exists(p):
                try:
                    os.startfile(os.path.abspath(p))
                except Exception:
                    messagebox.showinfo("GDS2 File", f"GDS2 File location:\n{os.path.abspath(p)}\n\nNotice: Open with KLayout or Magic layout editor.")
                return
        messagebox.showinfo("GDS2 File", "GDS2 file not found.")

def find_layout_images():
    cur_dir = os.path.dirname(os.path.abspath(__file__))
    candidates = [
        (os.path.join(cur_dir, "..", "results", "layout_renders", "gds_layout_full_chip.png"),
         os.path.join(cur_dir, "..", "results", "layout_renders", "gds_layout_core_zoom.png")),
        (os.path.join(cur_dir, "gds_layout_renders", "gds_layout_full_chip.png"),
         os.path.join(cur_dir, "gds_layout_renders", "gds_layout_core_zoom.png")),
        (os.path.join(cur_dir, "..", "gds_layout_renders", "gds_layout_full_chip.png"),
         os.path.join(cur_dir, "..", "gds_layout_renders", "gds_layout_core_zoom.png")),
    ]
    for full_path, zoom_path in candidates:
        if os.path.exists(full_path):
            return full_path, zoom_path
    return candidates[0]

if __name__ == '__main__':
    full_img, zoom_img = find_layout_images()
    if not os.path.exists(full_img):
        print(f"Error: layout render '{full_img}' not found.")
        sys.exit(1)

    print("Launching Interactive GDSII Layout Viewer...")
    app = GDSViewer(full_img, zoom_img)
    if "--no-gui" in sys.argv:
        print("[OK] GDSViewer initialized successfully in test mode.")
        app.destroy()
    else:
        app.mainloop()
