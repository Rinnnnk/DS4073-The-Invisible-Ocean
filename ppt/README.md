# Master slide deck

`build_master_deck.py` builds a single 16:9 English deck scaffold for the whole
project, modelled on `module_C/DS4073_C_T07_T09/make_page_slides.py`.

## Deck structure

| Slides | Content |
|---|---|
| 1 | Title - project name, subtitle, presenters |
| 2-4 | Background, dataset/preprocessing, methodology bullet placeholders |
| 5-19 | Fifteen task slides (T01-T15), each tagged with a speaker placeholder |
| 20 | Conclusion placeholder |

## Build

```sh
pip install python-pptx
python build_master_deck.py
```

This writes `Master_Deck_Scaffold.pptx` next to the script. The script is a scaffold:
it lays out the structure but uses `TODO` text instead of final figures. Replace each
`TODO` and each `[Speaker Name / Student ID]` before submission.

## Conventions

- English only, ASCII only.
- One module per slide group: A (T01-T03), B (T04-T06), C (T07-T09),
  D (T10-T12), E (T13-T15).
- Keep the master deck in sync with `dashboard/index.Rmd` and the report.