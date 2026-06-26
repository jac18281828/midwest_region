#!/usr/bin/env bash
set -euo pipefail

OUT=/output
mkdir -p "${OUT}"

# 13 ODP Midwest Region state associations, as DCW (ISO) codes.
STATES="US.IL,US.IN,US.IA,US.KS,US.KY,US.MI,US.MN,US.MO,US.NE,US.ND,US.OH,US.SD,US.WI"

# Bounding box: the union of the 13 states with a little padding.
WEST=-104.5
EAST=-80.0
SOUTH=35.8
NORTH=49.6
REGION="-R${WEST}/${EAST}/${SOUTH}/${NORTH}"

# Mercator projection, ~25 cm wide -> ~2950 px wide at 300 dpi (letter-class).
PROJ="-JM25c"

# Mercyhealth Sportscore Two, Loves Park, IL (Google place pin: lon lat).
MARK_LON=-88.9445
MARK_LAT=42.3220

# Generalization tolerance (Douglas-Peucker). 5 km is a good presentation default.
SIMPLIFY=5k

# Line weight for the generalized border.
PEN=2p,black

WORK=/tmp/midwest_work
mkdir -p "${WORK}"
PS="${WORK}/midwest.ps"

# --- Step 1: extract the 13-state borders and generalize them -----------------
# Dump the DCW state polygons as a multisegment table (-M, no plotting), then
# simplify (decimate) to remove the fine river/coast meanders that look noisy at
# this scale. -fg treats coordinates as geographic so -T is in kilometres.
gmt coast ${REGION} -E${STATES} -M -Vq > "${WORK}/states.txt"
gmt simplify "${WORK}/states.txt" -T${SIMPLIFY} -fg > "${WORK}/states_simplified.txt"

# --- Step 2: render via classic PostScript pipeline ---------------------------
# Round joins/caps make the generalized polyline read smoothly for presentation.
gmt set PS_MEDIA letter PS_PAGE_ORIENTATION landscape \
        MAP_ORIGIN_X 1c MAP_ORIGIN_Y 1c \
        PS_LINE_JOIN round PS_LINE_CAP round

# Classic (legacy) GMT mode: write a PostScript file directly.
# First command opens the PS (-K); last command closes it (-O without -K).

# Draw the generalized 13-state outlines from the simplified multisegment file.
gmt psxy "${WORK}/states_simplified.txt" ${REGION} ${PROJ} \
    -W${PEN} \
    -K -P > "${PS}"

# Marker: 0.5 cm black filled circle at Sportscore Two (classic mode uses psxy).
echo "${MARK_LON} ${MARK_LAT}" | gmt psxy ${REGION} ${PROJ} \
    -Sc0.5c -Gblack \
    -O >> "${PS}"

# Convert PS -> PNG with transparency, cropped to artwork, 300 dpi.
# -TG = PNG with transparency, -A = crop to artwork bounding box, -E300 = 300 dpi.
gmt psconvert "${PS}" -TG -A -E300 -D"${OUT}" -F"midwest"

echo "Wrote ${OUT}/midwest.png"
ls -l "${OUT}/midwest.png"
