#!/usr/bin/env bash
set -euo pipefail

OUT=/output
mkdir -p "${OUT}"
WORK=/tmp/midwest_work
mkdir -p "${WORK}"

# 13 ODP Midwest Region state associations, as DCW (ISO) codes.
STATES="US.IL,US.IN,US.IA,US.KS,US.KY,US.MI,US.MN,US.MO,US.NE,US.ND,US.OH,US.SD,US.WI"

# Bounding box: union of the 13 states with a little padding.
REGION="-R-104.5/-80.0/35.8/49.6"

# Mercator, ~25 cm wide -> ~2950 px at 300 dpi (letter-class).
PROJ="-JM25c"

# Mercyhealth Sportscore Two, Loves Park, IL (Google place pin: lon lat).
MARK_LON=-88.9445
MARK_LAT=42.3220

# Cartography knobs.
RES=i              # GSHHG/WDBII resolution: i=intermediate (atlas-quality, smooth).
AREA=5000          # drop water bodies < this many km^2 (keeps only Great Lakes).
TOL=6k             # border generalization (Douglas-Peucker). LIGHT on purpose:
                   # it strips river noise but leaves straight political borders
                   # as clean 2-point lines (which the spline keeps straight).
SPLINE=2k          # Akima spline resample step. Rounds the remaining river
                   # chords into smooth flowing curves (kills the "cartoonish"
                   # faceting) without rounding the sharp state corners.
BUF=0.18           # clip-mask dilation (deg). Must exceed the border deviation so
                   # the perimeter renders at full pen width (not clipped to half).
PEN=2.4p,black     # state / national border pen (solid, professional weight).
LAKEPEN=1.2p,black # Great Lakes shoreline pen (thin -> outlines the water).
LAKEFILL="#d9d9d9" # Great Lakes water fill (~15% grey) for land/water separation.

# Golden three-ring bullseye venue marker (diameters in ~phi progression), so the
# location reads as a deliberate target instead of an "owl eye" or a drowned dot.
B_OUT=1.25c        # outer ring diameter.
B_MID=0.77c        # middle ring diameter (~ B_OUT / phi).
B_IN=0.28c         # inner filled dot diameter.
RINGPEN=1.8p,black # ring pen (a touch lighter than borders, reads as a marker).

# --- 1. DCW polygons of the 13 states -> dilated clip mask --------------------
# Dump the state polygons (never drawn: their edges are political and cross the
# Great Lakes); buffer outward by BUF so perimeter linework is not clipped thin.
gmt coast ${REGION} -E${STATES} -M -Vq > "${WORK}/states.txt"
gmt spatial "${WORK}/states.txt" -Sb${BUF} -fg > "${WORK}/mask.txt"

# --- 2. Border network -> generalized + spline-smoothed -----------------------
# Dump the WDBII border network (single network -> drawn once, no doubling),
# lightly simplify to strip river noise, then Akima-spline resample so the
# remaining curves are smooth (not faceted). Plotted (not -N) for full control.
gmt coast ${REGION} -N1 -N2 -M -D${RES} -A${AREA} -Vq > "${WORK}/borders.txt"
gmt simplify "${WORK}/borders.txt" -T${TOL} -fg > "${WORK}/borders_s.txt"
gmt sample1d "${WORK}/borders_s.txt" -Ar -Fa -T${SPLINE} -fg > "${WORK}/borders_sm.txt"

# --- 3. Render ----------------------------------------------------------------
# Plot to PostScript, then psconvert with -TG. The modern "png,...,TG" shortcut
# does NOT yield a real alpha channel in this GMT build, so transparency must be
# produced explicitly by psconvert (-TG = PNG with transparent background).
gmt begin "${WORK}/midwest" ps
    gmt set PS_LINE_JOIN round PS_LINE_CAP round PS_MEDIA letter

    # Lakes as a self-contained layer, UNMASKED so each Great Lake fills and
    # outlines to its true shoreline (grey water + thin black outline = bounded,
    # not floating). -S fills water only; land stays transparent.
    gmt coast ${REGION} ${PROJ} -D${RES} -A${AREA} -S${LAKEFILL}
    gmt coast ${REGION} ${PROJ} -D${RES} -A${AREA} -W${LAKEPEN}

    # Political borders: generalized, masked to the 13 states, and drawn ONLY
    # over land (nested land clip) so mid-lake political lines never appear.
    gmt clip "${WORK}/mask.txt" ${REGION} ${PROJ}
        gmt coast ${REGION} ${PROJ} -D${RES} -A${AREA} -Gc
            gmt plot "${WORK}/borders_sm.txt" ${REGION} ${PROJ} -W${PEN}
        gmt coast ${REGION} ${PROJ} -Q
    gmt clip -C

    # Bullseye marker: outer ring, middle ring, filled center (drawn last, on top).
    echo "${MARK_LON} ${MARK_LAT}" | gmt plot ${REGION} ${PROJ} -Sc${B_OUT} -W${RINGPEN}
    echo "${MARK_LON} ${MARK_LAT}" | gmt plot ${REGION} ${PROJ} -Sc${B_MID} -W${RINGPEN}
    echo "${MARK_LON} ${MARK_LAT}" | gmt plot ${REGION} ${PROJ} -Sc${B_IN}  -Gblack
gmt end

# Transparent, cropped, 300 dpi PNG (raster) ...
gmt psconvert "${WORK}/midwest.ps" -TG -A -E300 -D"${OUT}" -Fmidwest
# ... and a cropped vector PDF (scalable; convert to SVG with e.g. pdf2svg/Inkscape).
gmt psconvert "${WORK}/midwest.ps" -Tf -A -D"${OUT}" -Fmidwest

echo "Wrote ${OUT}/midwest.png and ${OUT}/midwest.pdf"
ls -l "${OUT}/midwest.png" "${OUT}/midwest.pdf"
