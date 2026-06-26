# ODP Midwest Region — 13-state outline PNG

Renders a transparent-background PNG of the 13 US Youth Soccer ODP Midwest Region
state outlines (IL, IN, IA, KS, KY, MI, MN, MO, NE, ND, OH, SD, WI) with a
black filled circle marking Mercyhealth Sportscore Two in Loves Park, IL.

No ETOPO/bedrock elevation data required — uses GMT's built-in DCW political polygons.

## Requirements

- Docker

## Build and run

```bash
docker build -t midwest-region .
docker run --rm -v "$(pwd)/output:/output" midwest-region
```

The result is `output/midwest.png`: a ~300 dpi transparent PNG with the 13-state
black border outline and the Sportscore Two venue marker.
