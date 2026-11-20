"""Build an offline C HTML page and three PowerPoint task slides from verified R figures."""
from pathlib import Path
from base64 import b64encode
from html import escape
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.text import PP_ALIGN, MSO_ANCHOR
from PIL import Image

base = Path(__file__).resolve().parent
figs = [
    ("T07", "Annual gear ranking", "T07_gear_ranking.png",
     "Trawlers: 59.37 million hours (53.15%). 'Fishing' is unspecified gear: 17.75%.",
     "Bar length uses annual hours on a common zero baseline. Unspecified gear is gray."),
    ("T08", "Monthly gear composition", "T08_monthly_gear_mix.png",
     "Trawlers remain largest, ranging from 39.12% in May to 58.22% in February.",
     "Each bar uses that month's hours as denominator. Categories and colors stay fixed."),
    ("T09", "Where named gears were observed", "T09_gear_maps.png",
     "Trawlers, drifting longlines, and set gillnets show different spatial footprints.",
     "All panels use 1-degree cells and one color range. Blank means no positive recorded hours."),
]

cards = []
for task, title, filename, finding, method in figs:
    data = b64encode((base / "results" / "figures" / filename).read_bytes()).decode("ascii")
    cards.append(f'''<section id="{task.lower()}"><div class="eyebrow">{task} · MEMBER C</div>
<h2>{escape(title)}</h2><p class="lead">{escape(finding)}</p>
<img src="data:image/png;base64,{data}" alt="{escape(title)} chart">
<p class="method">{escape(method)}</p></section>''')
html = f'''<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1"><title>The Invisible Ocean | Member C</title>
<style>body{{margin:0;background:#eff4f5;color:#173443;font:17px/1.55 Arial,sans-serif}}
header{{background:#173443;color:white;padding:36px max(4vw,20px)}}h1{{margin:0 0 5px;font-size:32px}}
header p{{margin:0;color:#b6d8d9}}nav{{padding:12px 4vw;background:white;position:sticky;top:0}}
nav a{{color:#176c73;margin-right:22px;font-weight:bold}}main{{max-width:1120px;margin:auto;padding:20px}}
section{{background:white;margin:22px 0;padding:24px 32px;box-shadow:0 2px 12px #b8c8cc55}}
.eyebrow{{color:#247c83;font-weight:bold;letter-spacing:.08em}}h2{{margin:4px 0 8px}}
.lead{{font-size:20px}}img{{width:100%;height:auto;display:block;margin:22px auto}}
.method{{color:#49616a}}footer{{max-width:1120px;margin:30px auto;padding:0 20px;color:#49616a}}
</style></head><body><header><h1>The Invisible Ocean</h1><p>2023 apparent fishing activity · Member C · Gear classification</p></header>
<nav><a href="#t07">T07 ranking</a><a href="#t08">T08 monthly mix</a><a href="#t09">T09 maps</a></nav>
<main>{''.join(cards)}</main><footer>Source: Global Fishing Watch fleet monthly data v3.0, 2023. Apparent fishing hours are AIS-based estimates, not catch. T09 cell size varies in physical area by latitude.</footer></body></html>'''
(base / "C_T07_T09.html").write_text(html, encoding="utf-8")

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
    slide.shapes.add_picture(str(img_path), Inches(.42 + (8.55-w)/2), Inches(1.30 + (5.75-h)/2), width=Inches(w), height=Inches(h))
    textbox(slide, 9.25, 1.45, 3.6, 1.60, finding, 20, navy, True)
    textbox(slide, 9.25, 3.43, 3.6, 1.63, method, 15, muted)
    textbox(slide, 9.25, 5.55, 3.6, .7, "R: readRDS / aggregate / barplot / image", 12, teal)
    textbox(slide, .48, 7.08, 5.0, .22, "Global Fishing Watch v3.0 · 2023", 9, muted)
    textbox(slide, 9.25, 7.02, 3.7, .28, "Presenter: [Your name / student ID]", 10, muted)
prs.save(base / "C_T07_T09_slides.pptx")
check = Presentation(base / "C_T07_T09_slides.pptx")
assert len(check.slides) == 3
print("Built HTML and", len(check.slides), "slides")
