"""Build D's three PowerPoint task slides from the verified R figures.

Run from this directory:  python make_page_slides.py
Output: D_T10_T12_slides.pptx (3 slides, one per task).
"""
from pathlib import Path

from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import MSO_ANCHOR
from PIL import Image

base = Path(__file__).resolve().parent

# task, slide title, figure, headline finding, how the chart is built
figs = [
    ("T10", "Which flags carry the fishing hours?",
     "T10_flag_ranking.png",
     "China alone: 52.51 million hours (47.00%). Unknown flags rank second at 10.03 million (8.98%).",
     "Bar length is annual hours on one shared zero baseline. The grey bar pools the 195 "
     "smallest flags, so it is a group, not a fleet."),
    ("T11", "Each flag fishes in its own corner",
     "T11_flag_area.png",
     "CHN takes 91% of its hours in the Northwest Pacific, GBR 95% in the Northeast "
     "Atlantic; TWN spreads over three areas.",
     "Rows are normalized by each flag's own annual total, so every row sums to 100%. "
     "Read across, not down. White cells are zero hours."),
    ("T12", "Three flags take most of an area",
     "T12_top3_flags_by_area.png",
     "Median top-three share is 70.6%, from 45.6% (Northeast Atlantic) to 100% "
     "(Arctic Sea, only three flags there).",
     "The ranking excludes UNKNOWN and UNK_UNRESOLVED, but the denominator keeps their "
     "hours. Grid centres outside FAO polygons are shown apart."),
]

prs = Presentation()
prs.slide_width = Inches(13.333)
prs.slide_height = Inches(7.5)
navy = RGBColor(23, 52, 67)
teal = RGBColor(36, 124, 131)
muted = RGBColor(73, 97, 106)


def textbox(slide, x, y, w, h, text, size, color=navy, bold=False):
    box = slide.shapes.add_textbox(Inches(x), Inches(y), Inches(w), Inches(h))
    tf = box.text_frame
    tf.clear()
    tf.word_wrap = True
    tf.vertical_anchor = MSO_ANCHOR.MIDDLE
    p = tf.paragraphs[0]
    p.text = text
    p.font.name = "Aptos"
    p.font.size = Pt(size)
    p.font.bold = bold
    p.font.color.rgb = color
    return box


for task, title, filename, finding, method in figs:
    slide = prs.slides.add_slide(prs.slide_layouts[6])
    textbox(slide, .45, .24, 10.8, .38, f"{task}  |  THE INVISIBLE OCEAN", 13, teal, True)
    textbox(slide, .45, .60, 12.4, .55, title, 27, navy, True)
    img_path = base / "results" / "figures" / filename
    with Image.open(img_path) as im:
        aspect = im.width / im.height
    max_w, max_h = 8.55, 5.75
    w, h = (max_w, max_w / aspect) if max_w / aspect <= max_h else (max_h * aspect, max_h)
    slide.shapes.add_picture(str(img_path), Inches(.42 + (8.55 - w) / 2),
                             Inches(1.30 + (5.75 - h) / 2), width=Inches(w), height=Inches(h))
    textbox(slide, 9.25, 1.40, 3.6, 1.75, finding, 20 if len(finding) <= 100 else 18, navy, True)
    textbox(slide, 9.25, 3.40, 3.6, 1.70, method, 15, muted)
    textbox(slide, 9.25, 5.55, 3.6, .7, "R: read.csv / aggregate / ggplot2", 12, teal)
    textbox(slide, .48, 7.08, 5.0, .22, "Global Fishing Watch v3.0 · 2023", 9, muted)
    textbox(slide, 9.25, 7.02, 3.7, .28, "Presenter: [Your name / student ID]", 10, muted)

prs.save(base / "D_T10_T12_slides.pptx")
check = Presentation(base / "D_T10_T12_slides.pptx")
assert len(check.slides) == 3
print("Built", len(check.slides), "slides")
