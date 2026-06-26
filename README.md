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

The result is `output/midwest.png`: a ~300 dpi transparent PNG with the 13-state
black border outline and the Sportscore Two venue marker.
