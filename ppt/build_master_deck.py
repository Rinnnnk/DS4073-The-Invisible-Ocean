"""Build the unified English slide deck scaffold for The Invisible Ocean.

Run: python build_master_deck.py
Requires: python-pptx
Lays out the title, background, 15 task, and conclusion slides with TODO text.
"""
from pathlib import Path

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR

base = Path(__file__).resolve().parent
out_path = base / "Master_Deck_Scaffold.pptx"

NAVY = RGBColor(23, 52, 67)
TEAL = RGBColor(36, 124, 131)
MUTED = RGBColor(73, 97, 106)
WHITE = RGBColor(255, 255, 255)
LIGHT = RGBColor(220, 232, 234)
SOFT = RGBColor(182, 216, 217)

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
BLANK = prs.slide_layouts[6]


def textbox(slide, x, y, w, h, text, size, color=NAVY, bold=False, align=PP_ALIGN.LEFT):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.clear()
    tf.word_wrap = True
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    p = tf.paragraphs[0]
    p.text = text
    p.alignment = align
    p.font.name = "Aptos"
    p.font.size = Pt(size)
    p.font.bold = bold
    p.font.color.rgb = color
    return box


def background(slide, color):
    fill = slide.background.fill
    fill.solid()
    fill.fore_color.rgb = color


def footer(slide, speaker=False):
    textbox(slide, 0.48, 7.08, 8.0, 0.25, "Global Fishing Watch v3.0 - 2023", 9, MUTED)
    if speaker:
        textbox(slide, 8.6, 7.02, 4.3, 0.3, "[Speaker Name / Student ID]", 10,
                MUTED, align=PP_ALIGN.RIGHT)


# --- Title slide ---
slide = prs.slides.add_slide(BLANK)
background(slide, NAVY)
textbox(slide, 0.8, 2.2, 11.6, 1.0, "The Invisible Ocean", 48, WHITE, True)
textbox(slide, 0.8, 3.25, 11.6, 0.7,
        "2023 Global Fishing Watch Visual Analytics", 26, SOFT)
textbox(slide, 0.8, 4.2, 11.6, 0.5,
        "DS4073 Data Visualization - Group Project", 18, LIGHT)
textbox(slide, 0.8, 6.4, 11.6, 0.4, "Presenters: [Speaker Name / Student ID]",
        13, SOFT)

# --- Background and methodology slides ---
sections = [
    ("Background and motivation",
     ["Why fishing is invisible",
      "AIS-based apparent fishing hours",
      "One shared dataset for all modules"]),
    ("Dataset and preprocessing",
     ["GFW v3.0 fleet monthly CSVs, 2023",
      "Month x 0.1 degree grid x flag x gear",
      "Reconciled total: 111,712,128.6941 hours"]),
    ("Methodology and design",
     ["Five modules A-E, fifteen tasks T01-T15",
      "Shared colour, scales, and denominators",
      "Integrated flexdashboard and report"]),
]
for title, bullets in sections:
    slide = prs.slides.add_slide(BLANK)
    textbox(slide, 0.6, 0.5, 12.0, 0.7, title, 30, NAVY, True)
    body = slide.shapes.add_textbox(Inches(0.9), Inches(1.7), Inches(11.6), Inches(4.8))
    tf = body.text_frame
    tf.clear()
    tf.word_wrap = True
    for i, point in enumerate(bullets):
        p = tf.paragraphs[0] if i == 0 else tf.add_paragraph()
        p.text = "- " + point
        p.font.name = "Aptos"
        p.font.size = Pt(22)
        p.font.color.rgb = MUTED
        p.space_after = Pt(14)
    footer(slide, speaker=True)

# --- Fifteen task slides ---
tasks = [
    ("T01", "A", "Where is fishing activity observed?"),
    ("T02", "A", "Which FAO marine areas dominate?"),
    ("T03", "A", "How concentrated are fishing hours?"),
    ("T04", "B", "How do fishing hours vary by month?"),
    ("T05", "B", "How does average daily effort vary?"),
    ("T06", "B", "Which month peaks in each FAO area?"),
    ("T07", "C", "Which gear types dominate?"),
    ("T08", "C", "How does the gear mix change by month?"),
    ("T09", "C", "Where are the leading gears observed?"),
    ("T10", "D", "Which vessel flags dominate?"),
    ("T11", "D", "How is flag activity distributed by area?"),
    ("T12", "D", "Top three known flags per area?"),
    ("T13", "E", "Which grid cells are hotspots?"),
    ("T14", "E", "Which flags dominate the hotspots?"),
    ("T15", "E", "How does the hotspot gear mix compare?"),
]
for code, module, question in tasks:
    slide = prs.slides.add_slide(BLANK)
    textbox(slide, 0.45, 0.24, 10.8, 0.38,
            f"{code}  |  MODULE {module}  |  THE INVISIBLE OCEAN", 13, TEAL, True)
    textbox(slide, 0.45, 0.70, 12.4, 1.0, question, 30, NAVY, True)
    textbox(slide, 0.45, 2.1, 12.4, 0.5,
            "TODO: insert the finished figure and one key finding for this task.",
            16, MUTED)
    textbox(slide, 0.45, 4.4, 12.4, 0.5,
            "TODO: method note - chart type, encoding, and denominator.", 14, MUTED)
    footer(slide, speaker=True)

# --- Conclusion slide ---
slide = prs.slides.add_slide(BLANK)
background(slide, NAVY)
textbox(slide, 0.8, 2.0, 11.6, 0.9, "Conclusion", 42, WHITE, True)
textbox(slide, 0.8, 3.1, 11.6, 1.5,
        "TODO: summarise the reconciled findings across modules A-E and the main "
        "message about the invisible ocean.", 20, LIGHT)
textbox(slide, 0.8, 6.4, 11.6, 0.4, "Thank you - questions welcome", 16, SOFT)

prs.save(out_path)
check = Presentation(out_path)
print("Built", len(check.slides), "slides ->", out_path.name)