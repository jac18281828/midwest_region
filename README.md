# ODP Midwest Region — 13-state outline PNG

Renders a transparent-background PNG of the 13 US Youth Soccer ODP Midwest Region
state outlines (IL, IN, IA, KS, KY, MI, MN, MO, NE, ND, OH, SD, WI) with a
bullseye marker at Mercyhealth Sportscore Two in Loves Park, IL.

No ETOPO/bedrock elevation data required. The 13 states are isolated with a DCW
political-polygon clip mask; the visible linework is GMT's WDBII border network
(state + national), lightly generalized and Akima-spline-smoothed for clean
flowing curves, drawn over land only, plus GSHHG shorelines. The Great Lakes
render as real water bodies — filled ~15% grey for instant land/water separation
— rather than mid-lake political lines.

## Requirements

- Docker

## Build and run

```bash
docker build -t midwest-region .
docker run --rm -v "$(pwd)/output:/output" midwest-region
```

Outputs `output/midwest.png` (transparent ~300 dpi raster) and `output/midwest.pdf`
(vector). All knobs are named variables at the top of `build_map.sh`.

## Design notes (hard-won — read before changing the pipeline)

These are the non-obvious decisions that make it look professional. Full rationale
is in `PROMPT-ADDENDUM-03.md`; the short version:

- **Borders = WDBII network (`-N1 -N2`), not DCW polygon edges.** DCW gives each
  state as a closed polygon, so shared borders draw twice and ghost. WDBII is one
  network → each border drawn once.
- **Smooth curves = LIGHT `gmt simplify` (6k) THEN Akima `gmt sample1d` spline.**
  Simplify alone looks faceted/cartoonish. Spline alone on heavily-simplified data
  rounds the sharp rectangular state corners and waves straight political borders.
  Light simplify keeps straight borders as 2-point lines (spline can't bend them),
  so only river borders smooth. Use Akima (`-Fa`), not cubic (overshoots).
- **Only-13-states = DCW polygons as a clip mask, dilated (`gmt spatial -Sb`).**
  Without dilation the perimeter sits on the clip edge and renders at half pen
  width. The dilation must exceed the border's deviation from the mask.
- **No mid-lake political lines = draw borders under a nested land clip
  (`gmt coast -Gc … -Q`).** DCW/WDBII boundaries run down the middle of the lakes.
- **Lakes filled + outlined UNMASKED** so each lake reaches its true shoreline
  (no straight cutoff where our states meet Canada). `-A5000` keeps only the
  Great Lakes.
- **Transparency = `gmt psconvert -TG`.** The modern `gmt begin … png,…,TG`
  shortcut silently produced opaque RGB in this GMT build. Plot to PS, then
  psconvert. (PDF needs no special flag — nothing paints the background.)
- **No elevation data / bedrock image needed** — this is a vector political map.
