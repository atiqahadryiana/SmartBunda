"""
SmartBunda — Actor / Feature FLOWCHART (A4 landscape PDF, pink & white theme).

A final-year-project presentation diagram: a central app hub flows out to the
five actors (Patient, Doctor, Nurse, Dietitian, Admin). Each actor branch shows
its features with a small vector icon per feature category.

Feature lists are taken verbatim from the app's role module definitions in
lib/screens/patient/role_modules_screen.dart and the permission sets in
lib/models/app_user.dart, so the diagram matches the implemented RBAC.

Icons are drawn as simple vector glyphs (no external assets needed).

Run:
    py -3.14 tools/generate_actor_features_diagram.py
Output:
    docs/smartbunda_actor_features.pdf
"""

import math
import os

from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib.units import mm
from reportlab.lib.colors import HexColor, white
from reportlab.pdfgen import canvas

# ── Theme ──────────────────────────────────────────────────────────────────
PINK_DEEP = HexColor("#AD1457")
PINK = HexColor("#E91E63")
PINK_MED = HexColor("#F06292")
PINK_SOFT = HexColor("#F8BBD0")
PINK_TINT = HexColor("#FCE4EC")
PINK_WASH = HexColor("#FDF2F7")
INK = HexColor("#3A2F33")
MUTE = HexColor("#9A8087")
WHITE = white

PAGE_W, PAGE_H = landscape(A4)  # 841.89 x 595.27 pt (297 x 210 mm)


# ── Vector icon glyphs ──────────────────────────────────────────────────────
# Each icon is drawn centred at (cx, cy) within a box of half-size s (pt).
def _stroke(c, color=None, w=1.1):
    c.setStrokeColor(color or PINK_DEEP)
    c.setLineWidth(w)
    c.setLineCap(1)
    c.setLineJoin(1)


def ic_person(c, cx, cy, s, col):
    _stroke(c, col)
    c.circle(cx, cy + s * 0.45, s * 0.34, fill=0, stroke=1)
    c.arc(cx - s * 0.6, cy - s * 0.95, cx + s * 0.6, cy + s * 0.25, 0, 180)


def ic_users(c, cx, cy, s, col):
    ic_person(c, cx - s * 0.35, cy, s * 0.78, col)
    ic_person(c, cx + s * 0.42, cy, s * 0.78, col)


def ic_dashboard(c, cx, cy, s, col):
    _stroke(c, col)
    c.roundRect(cx - s * 0.8, cy - s * 0.7, s * 0.7, s * 1.4, 1.2, stroke=1, fill=0)
    c.roundRect(cx + s * 0.1, cy + s * 0.0, s * 0.7, s * 0.7, 1.2, stroke=1, fill=0)
    c.roundRect(cx + s * 0.1, cy - s * 0.7, s * 0.7, s * 0.55, 1.2, stroke=1, fill=0)


def ic_meal(c, cx, cy, s, col):
    _stroke(c, col)
    c.circle(cx + s * 0.1, cy, s * 0.7, stroke=1, fill=0)          # plate
    c.line(cx - s * 0.75, cy + s * 0.7, cx - s * 0.75, cy - s * 0.7)  # fork stem
    for dx in (-0.95, -0.75, -0.55):
        c.line(cx + dx * s, cy + s * 0.7, cx + dx * s, cy + s * 0.35)


def ic_water(c, cx, cy, s, col):
    _stroke(c, col)
    p = c.beginPath()
    p.moveTo(cx, cy + s * 0.85)
    p.curveTo(cx + s * 0.7, cy + s * 0.1, cx + s * 0.55, cy - s * 0.8, cx, cy - s * 0.8)
    p.curveTo(cx - s * 0.55, cy - s * 0.8, cx - s * 0.7, cy + s * 0.1, cx, cy + s * 0.85)
    c.drawPath(p, stroke=1, fill=0)


def ic_assess(c, cx, cy, s, col):  # clipboard / checklist
    _stroke(c, col)
    c.roundRect(cx - s * 0.6, cy - s * 0.85, s * 1.2, s * 1.7, 1.5, stroke=1, fill=0)
    c.rect(cx - s * 0.22, cy + s * 0.7, s * 0.44, s * 0.22, stroke=1, fill=0)
    for i, yy in enumerate((0.35, 0.0, -0.35)):
        c.line(cx - s * 0.35, cy + yy * s, cx + s * 0.35, cy + yy * s)


def ic_monitor(c, cx, cy, s, col):  # heart-pulse
    _stroke(c, col)
    p = c.beginPath()
    p.moveTo(cx - s * 0.85, cy)
    p.lineTo(cx - s * 0.35, cy)
    p.lineTo(cx - s * 0.15, cy + s * 0.55)
    p.lineTo(cx + s * 0.1, cy - s * 0.55)
    p.lineTo(cx + s * 0.3, cy)
    p.lineTo(cx + s * 0.85, cy)
    c.drawPath(p, stroke=1, fill=0)


def ic_calendar(c, cx, cy, s, col):
    _stroke(c, col)
    c.roundRect(cx - s * 0.8, cy - s * 0.75, s * 1.6, s * 1.4, 1.5, stroke=1, fill=0)
    c.line(cx - s * 0.8, cy + s * 0.3, cx + s * 0.8, cy + s * 0.3)
    c.line(cx - s * 0.4, cy + s * 0.65, cx - s * 0.4, cy + s * 0.95)
    c.line(cx + s * 0.4, cy + s * 0.65, cx + s * 0.4, cy + s * 0.95)


def ic_report(c, cx, cy, s, col):  # bar chart
    _stroke(c, col)
    c.line(cx - s * 0.8, cy - s * 0.75, cx - s * 0.8, cy + s * 0.85)
    c.line(cx - s * 0.8, cy - s * 0.75, cx + s * 0.85, cy - s * 0.75)
    for dx, h in ((-0.45, 0.35), (0.0, 0.75), (0.45, 0.5)):
        c.rect(cx + dx * s - s * 0.12, cy - s * 0.75, s * 0.24, h * s, stroke=1, fill=0)


def ic_book(c, cx, cy, s, col):
    _stroke(c, col)
    c.line(cx, cy - s * 0.8, cx, cy + s * 0.75)
    p = c.beginPath()
    p.moveTo(cx, cy + s * 0.75)
    p.curveTo(cx - s * 0.6, cy + s * 0.4, cx - s * 0.9, cy + s * 0.45, cx - s * 0.9, cy - s * 0.55)
    p.curveTo(cx - s * 0.5, cy - s * 0.8, cx - s * 0.2, cy - s * 0.7, cx, cy - s * 0.5)
    c.drawPath(p, stroke=1, fill=0)
    p2 = c.beginPath()
    p2.moveTo(cx, cy + s * 0.75)
    p2.curveTo(cx + s * 0.6, cy + s * 0.4, cx + s * 0.9, cy + s * 0.45, cx + s * 0.9, cy - s * 0.55)
    p2.curveTo(cx + s * 0.5, cy - s * 0.8, cx + s * 0.2, cy - s * 0.7, cx, cy - s * 0.5)
    c.drawPath(p2, stroke=1, fill=0)


def ic_analyze(c, cx, cy, s, col):  # magnifier
    _stroke(c, col)
    c.circle(cx - s * 0.15, cy + s * 0.15, s * 0.55, stroke=1, fill=0)
    c.line(cx + s * 0.3, cy - s * 0.3, cx + s * 0.85, cy - s * 0.85)


def ic_plan(c, cx, cy, s, col):  # checklist tasks
    _stroke(c, col)
    for i, yy in enumerate((0.6, 0.0, -0.6)):
        c.rect(cx - s * 0.85, cy + yy * s - s * 0.16, s * 0.32, s * 0.32, stroke=1, fill=0)
        c.line(cx - s * 0.35, cy + yy * s, cx + s * 0.85, cy + yy * s)


def ic_note(c, cx, cy, s, col):  # clinical note / pencil page
    _stroke(c, col)
    c.roundRect(cx - s * 0.65, cy - s * 0.85, s * 1.2, s * 1.7, 1.5, stroke=1, fill=0)
    for yy in (0.4, 0.05, -0.3):
        c.line(cx - s * 0.4, cy + yy * s, cx + s * 0.3, cy + yy * s)


def ic_vitals(c, cx, cy, s, col):  # stethoscope-ish / heart+plus
    _stroke(c, col)
    c.circle(cx, cy, s * 0.7, stroke=1, fill=0)
    c.line(cx - s * 0.32, cy, cx + s * 0.32, cy)
    c.line(cx, cy - s * 0.32, cx, cy + s * 0.32)


def ic_db(c, cx, cy, s, col):  # database cylinder
    _stroke(c, col)
    c.ellipse(cx - s * 0.6, cy + s * 0.45, cx + s * 0.6, cy + s * 0.85, stroke=1, fill=0)
    c.line(cx - s * 0.6, cy + s * 0.65, cx - s * 0.6, cy - s * 0.65)
    c.line(cx + s * 0.6, cy + s * 0.65, cx + s * 0.6, cy - s * 0.65)
    c.ellipse(cx - s * 0.6, cy - s * 0.85, cx + s * 0.6, cy - s * 0.45, stroke=1, fill=0)


def ic_content(c, cx, cy, s, col):  # document stack
    _stroke(c, col)
    c.roundRect(cx - s * 0.5, cy - s * 0.5, s * 1.1, s * 1.3, 1.2, stroke=1, fill=0)
    c.roundRect(cx - s * 0.75, cy - s * 0.75, s * 1.1, s * 1.3, 1.2, stroke=1, fill=0)


def ic_settings(c, cx, cy, s, col):  # gear (simplified)
    _stroke(c, col)
    c.circle(cx, cy, s * 0.4, stroke=1, fill=0)
    for k in range(8):
        a = k * math.pi / 4
        x0 = cx + math.cos(a) * s * 0.55
        y0 = cy + math.sin(a) * s * 0.55
        x1 = cx + math.cos(a) * s * 0.85
        y1 = cy + math.sin(a) * s * 0.85
        c.line(x0, y0, x1, y1)


def ic_lock(c, cx, cy, s, col):
    _stroke(c, col)
    c.roundRect(cx - s * 0.6, cy - s * 0.7, s * 1.2, s * 0.95, 1.5, stroke=1, fill=0)
    c.arc(cx - s * 0.4, cy + s * 0.0, cx + s * 0.4, cy + s * 0.85, 0, 180)


def ic_app(c, cx, cy, s, col):  # phone with heart
    _stroke(c, col, 1.4)
    c.roundRect(cx - s * 0.55, cy - s * 0.85, s * 1.1, s * 1.7, 2.2, stroke=1, fill=0)
    c.setFillColor(col)
    # tiny heart
    r = s * 0.16
    c.circle(cx - r, cy + r * 0.4, r, fill=1, stroke=0)
    c.circle(cx + r, cy + r * 0.4, r, fill=1, stroke=0)
    p = c.beginPath()
    p.moveTo(cx - 2 * r, cy + r * 0.4)
    p.lineTo(cx, cy - r * 1.4)
    p.lineTo(cx + 2 * r, cy + r * 0.4)
    c.drawPath(p, fill=1, stroke=0)


ICONS = {
    "person": ic_person, "users": ic_users, "dashboard": ic_dashboard,
    "meal": ic_meal, "water": ic_water, "assess": ic_assess,
    "monitor": ic_monitor, "calendar": ic_calendar, "report": ic_report,
    "book": ic_book, "analyze": ic_analyze, "plan": ic_plan, "note": ic_note,
    "vitals": ic_vitals, "db": ic_db, "content": ic_content,
    "settings": ic_settings, "lock": ic_lock, "app": ic_app,
}

# ── Actor data (icon, label) per feature — mirrors role_modules_screen.dart ──
ACTORS = [
    {
        "name": "Patient (Mother)", "icon": "person", "tag": "Pregnant / postnatal user",
        "features": [
            ("dashboard", "Daily summary & AI recommendation"),
            ("person", "Profile & pregnancy progress"),
            ("meal", "Meal log (manual + AI camera scan)"),
            ("water", "Hydration log"),
            ("assess", "Digital health assessments"),
            ("monitor", "Monitoring & calorie/risk alerts"),
            ("calendar", "Appointments & reminders"),
            ("report", "Reports & progress analytics"),
            ("book", "Education & trimester content"),
        ],
    },
    {
        "name": "Doctor", "icon": "person", "tag": "Healthcare professional",
        "features": [
            ("users", "Review patient profiles & pregnancy"),
            ("analyze", "Nutrition analysis & recommendation"),
            ("plan", "Nutrition plan management"),
            ("monitor", "Monitoring & critical-risk alerts"),
            ("note", "Clinical / consultation notes"),
            ("calendar", "Appointments & follow-ups"),
            ("report", "Reports & compliance insights"),
        ],
    },
    {
        "name": "Nurse", "icon": "person", "tag": "Healthcare professional",
        "features": [
            ("users", "Review patient profiles & pregnancy"),
            ("vitals", "Record per-visit vitals (wt, Hb, BP)"),
            ("monitor", "Monitoring & critical-risk alerts"),
            ("note", "Clinical / consultation notes"),
            ("calendar", "Appointments & follow-ups"),
            ("report", "Reports & compliance insights"),
        ],
    },
    {
        "name": "Dietitian", "icon": "person", "tag": "Healthcare professional",
        "features": [
            ("users", "Review patient profiles & pregnancy"),
            ("analyze", "Nutrition analysis & recommendation"),
            ("plan", "Build & approve nutrition plans"),
            ("monitor", "Monitoring & critical-risk alerts"),
            ("note", "Clinical / consultation notes"),
            ("calendar", "Appointments & follow-ups"),
            ("report", "Reports & compliance insights"),
        ],
    },
    {
        "name": "Admin", "icon": "settings", "tag": "System administrator",
        "features": [
            ("users", "User management & staff approval"),
            ("db", "Food database maintenance"),
            ("content", "Content & guideline management"),
            ("calendar", "Appointments oversight"),
            ("report", "Reporting & usage analytics"),
            ("settings", "Settings, backup & restore"),
            ("note", "Activity / audit logs"),
        ],
    },
]


def draw_background(c):
    c.setFillColor(PINK_WASH)
    c.rect(0, 0, PAGE_W, PAGE_H, fill=1, stroke=0)
    c.setFillColor(PINK)
    c.rect(0, PAGE_H - 18 * mm, PAGE_W, 18 * mm, fill=1, stroke=0)
    c.setFillColor(PINK_DEEP)
    c.rect(0, PAGE_H - 19 * mm, PAGE_W, 1 * mm, fill=1, stroke=0)


def draw_header(c):
    c.setFillColor(WHITE)
    c.setFont("Helvetica-Bold", 16)
    c.drawString(12 * mm, PAGE_H - 11 * mm, "SmartBunda  —  Features by Actor")
    c.setFont("Helvetica", 9)
    c.drawString(12 * mm, PAGE_H - 15.6 * mm,
                 "Maternal Nutrition System  ·  Role-Based Access Flowchart")
    c.setFont("Helvetica-Oblique", 8.5)
    c.setFillColor(PINK_TINT)
    c.drawRightString(PAGE_W - 12 * mm, PAGE_H - 13 * mm, "Final Year Project")


def wrap(c, text, font, size, max_w):
    c.setFont(font, size)
    words, lines, cur = text.split(), [], ""
    for w in words:
        trial = (cur + " " + w).strip()
        if c.stringWidth(trial, font, size) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = w
    if cur:
        lines.append(cur)
    return lines


def draw_hub(c, cx, cy):
    r = 17 * mm
    c.setFillColor(PINK_DEEP)
    c.circle(cx, cy, r + 1.6, fill=1, stroke=0)
    c.setFillColor(PINK_MED)
    c.circle(cx, cy, r, fill=1, stroke=0)
    ICONS["app"](c, cx, cy + 4.5, 11, WHITE)
    c.setFillColor(WHITE)
    c.setFont("Helvetica-Bold", 11)
    c.drawCentredString(cx, cy - 9, "SmartBunda")
    c.setFont("Helvetica", 7)
    c.drawCentredString(cx, cy - 15.5, "App Platform")


def elbow(c, x0, y0, x1, y1):
    """Orthogonal flowchart connector with arrowhead into the card (left edge)."""
    c.setStrokeColor(PINK_SOFT)
    c.setLineWidth(1.4)
    midx = (x0 + x1) / 2
    c.line(x0, y0, midx, y0)
    c.line(midx, y0, midx, y1)
    c.line(midx, y1, x1, y1)
    # arrowhead pointing right into card
    c.setFillColor(PINK_MED)
    a = 2.4
    p = c.beginPath()
    p.moveTo(x1, y1)
    p.lineTo(x1 - a * 1.6, y1 + a)
    p.lineTo(x1 - a * 1.6, y1 - a)
    p.close()
    c.drawPath(p, fill=1, stroke=0)


def draw_actor_card(c, x, y, w, h, actor):
    c.setFillColor(WHITE)
    c.setStrokeColor(PINK_SOFT)
    c.setLineWidth(1.1)
    c.roundRect(x, y, w, h, 3.2 * mm, fill=1, stroke=1)
    # header strip
    strip_h = 9 * mm
    c.setFillColor(PINK_TINT)
    c.roundRect(x, y + h - strip_h, w, strip_h, 3.2 * mm, fill=1, stroke=0)
    c.rect(x, y + h - strip_h, w, strip_h - 3.2 * mm, fill=1, stroke=0)
    # actor icon badge
    bx, by = x + 6 * mm, y + h - strip_h / 2
    c.setFillColor(PINK)
    c.circle(bx, by, 3.4 * mm, fill=1, stroke=0)
    ICONS[actor["icon"]](c, bx, by, 4.2, WHITE)
    c.setFillColor(PINK_DEEP)
    c.setFont("Helvetica-Bold", 9.5)
    c.drawString(x + 11 * mm, by + 0.6 * mm, actor["name"])
    c.setFillColor(MUTE)
    c.setFont("Helvetica-Oblique", 6.3)
    c.drawString(x + 11 * mm, by - 3.0 * mm, actor["tag"])

    # features w/ icons
    pad = 4 * mm
    fy = y + h - strip_h - 4.4 * mm
    line_h = 3.3 * mm
    for icon, label in actor["features"]:
        ICONS[icon](c, x + pad + 1.4 * mm, fy + 0.6 * mm, 2.5, PINK)
        c.setFillColor(INK)
        lines = wrap(c, label, "Helvetica", 7.0, w - pad - 7 * mm)
        for i, ln in enumerate(lines):
            c.drawString(x + pad + 5.0 * mm, fy - i * line_h, ln)
        fy -= line_h * len(lines) + 1.1 * mm


def draw_shared_chip(c, cx, cy):
    """Auth / RBAC node shown as a shared foundation block under the hub."""
    w, h = 64 * mm, 11 * mm
    x, y = cx - w / 2, cy - h / 2
    c.setFillColor(PINK_TINT)
    c.setStrokeColor(PINK_SOFT)
    c.setLineWidth(1)
    c.roundRect(x, y, w, h, 2.4 * mm, fill=1, stroke=1)
    ICONS["lock"](c, x + 6 * mm, y + h / 2, 3.0, PINK_DEEP)
    c.setFillColor(PINK_DEEP)
    c.setFont("Helvetica-Bold", 7.4)
    c.drawString(x + 11 * mm, y + h - 4 * mm, "Shared: Authentication & Security")
    c.setFillColor(INK)
    c.setFont("Helvetica", 6.3)
    c.drawString(x + 11 * mm, y + 2.6 * mm, "Login · password reset · session · RBAC (all roles)")


def draw_footer(c):
    c.setFillColor(MUTE)
    c.setFont("Helvetica", 6.4)
    c.drawString(12 * mm, 6 * mm,
                 "Generated from SmartBunda role definitions (role_modules_screen.dart / app_user.dart). "
                 "Data secured in Firebase with role-based Firestore rules.")
    c.drawRightString(PAGE_W - 12 * mm, 6 * mm, "SmartBunda · Actor / Feature Flowchart")


def build(path):
    c = canvas.Canvas(path, pagesize=landscape(A4))
    draw_background(c)
    draw_header(c)

    margin = 11 * mm
    top = PAGE_H - 22 * mm
    bottom = 11 * mm

    # Hub on the left-centre; actor cards in two columns on the right.
    hub_cx = 42 * mm
    hub_cy = (top + bottom) / 2 + 4 * mm
    draw_hub(c, hub_cx, hub_cy)
    draw_shared_chip(c, hub_cx, bottom + 6 * mm)

    # Two columns of cards to the right of the hub.
    col_gap = 7 * mm
    left_col_x = 78 * mm
    card_w = (PAGE_W - margin - left_col_x - col_gap) / 2
    col2_x = left_col_x + card_w + col_gap

    # Column 1: Patient (tall), Doctor.  Column 2: Nurse, Dietitian, Admin.
    # Give Patient extra height (9 features).
    avail_h = top - bottom
    # Col 1 layout — Patient sized to its 9 features, Doctor to its 7.
    p_h = 62 * mm
    d_h = 52 * mm
    gap1 = (avail_h - p_h - d_h)
    gap1 = max(gap1, 5 * mm)
    patient_y = top - p_h
    doctor_y = patient_y - gap1 - d_h

    # Col 2 layout: three cards (Nurse 6, Dietitian 7, Admin 7 features)
    n_h = 47 * mm
    di_h = 52 * mm
    a_h = 52 * mm
    gap2 = (avail_h - (n_h + di_h + a_h)) / 2
    gap2 = max(gap2, 4 * mm)
    nurse_y = top - n_h
    diet_y = nurse_y - gap2 - di_h
    admin_y = diet_y - gap2 - a_h

    cards = [
        (left_col_x, patient_y, card_w, p_h, ACTORS[0]),  # Patient
        (left_col_x, doctor_y, card_w, d_h, ACTORS[1]),   # Doctor
        (col2_x, nurse_y, card_w, n_h, ACTORS[2]),        # Nurse
        (col2_x, diet_y, card_w, di_h, ACTORS[3]),        # Dietitian
        (col2_x, admin_y, card_w, a_h, ACTORS[4]),        # Admin
    ]

    # Connectors first (so cards sit on top), only to column-1 cards from hub;
    # column-2 cards branch from a vertical spine for a clean flowchart look.
    hub_out_x = hub_cx + 17 * mm
    for (x, y, w, h, actor) in cards[:2]:
        elbow(c, hub_out_x, hub_cy, x, y + h - 4.5 * mm)
    # spine to column 2: branch off the elbow midline
    spine_x = (hub_out_x + left_col_x) / 2
    for (x, y, w, h, actor) in cards[2:]:
        c.setStrokeColor(PINK_SOFT)
        c.setLineWidth(1.4)
        midy = hub_cy
        c.line(hub_out_x, hub_cy, spine_x, hub_cy)
        ty = y + h - 4.5 * mm
        c.line(spine_x, midy, spine_x, ty)
        c.line(spine_x, ty, x, ty)
        c.setFillColor(PINK_MED)
        a = 2.4
        p = c.beginPath()
        p.moveTo(x, ty); p.lineTo(x - a * 1.6, ty + a); p.lineTo(x - a * 1.6, ty - a); p.close()
        c.drawPath(p, fill=1, stroke=0)

    for (x, y, w, h, actor) in cards:
        draw_actor_card(c, x, y, w, h, actor)

    draw_hub(c, hub_cx, hub_cy)  # redraw on top of lines
    draw_footer(c)
    c.showPage()
    c.save()
    print("Wrote", path)


if __name__ == "__main__":
    out = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "docs",
                                       "smartbunda_actor_features.pdf"))
    os.makedirs(os.path.dirname(out), exist_ok=True)
    build(out)
