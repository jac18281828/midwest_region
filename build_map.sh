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
DOT=0.4c            # circle diameter; drop to 0.3c only if it touches Wisconsin.

# Cartography knobs.
RES=l              # GSHHG/WDBII resolution: l=low (smooth), i=intermediate.
AREA=5000          # drop water bodies < this many km^2 (keeps only Great Lakes).
PEN=2p,black       # border / shoreline pen.

# --- 1. DCW polygons of the 13 states -> clip mask ----------------------------
# Dump the state polygons as a multisegment table. We do NOT plot these (their
# edges are *political*, so they run down the middle of the Great Lakes); we use
# them only to mask the GSHHG/WDBII linework below to the 13 states.
gmt coast ${REGION} -E${STATES} -M -Vq > "${WORK}/states.txt"

# --- 2. Render ----------------------------------------------------------------
# Plot to PostScript, then psconvert with -TG. The modern "png,...,TG" shortcut
# does NOT yield a real alpha channel in this GMT build, so transparency must be
# produced explicitly by psconvert (-TG = PNG with transparent background).
gmt begin "${WORK}/midwest" ps
    gmt set PS_LINE_JOIN round PS_LINE_CAP round PS_MEDIA letter

    # Mask everything to the 13 states (clip = union of the DCW polygons).
    gmt clip "${WORK}/states.txt" ${REGION} ${PROJ}

        # Political borders, drawn ONLY over land via a nested land clip, so the
        # mid-lake political lines never appear. -N1 = national (Canada border),
        # -N2 = state borders. WDBII borders are a single network, so shared
        # borders are drawn once -> no doubled/ghosted lines.
        gmt coast ${REGION} ${PROJ} -D${RES} -A${AREA} -Gc
            gmt coast ${REGION} ${PROJ} -D${RES} -A${AREA} -N1/${PEN} -N2/${PEN}
        gmt coast ${REGION} ${PROJ} -Q

        # Great Lakes shorelines (only our side shows, since under the state
        # mask). AREA=5000 keeps only the Great Lakes and drops inland lakes /
        # Missouri River reservoirs that would otherwise clutter the Dakotas.
        gmt coast ${REGION} ${PROJ} -D${RES} -A${AREA} -W${PEN}

    gmt clip -C

    # Marker: filled black circle at Sportscore Two, drawn on top.
    echo "${MARK_LON} ${MARK_LAT}" | gmt plot ${REGION} ${PROJ} -Sc${DOT} -Gblack
gmt end

# Convert to a transparent, cropped, 300 dpi PNG.
#   -TG = PNG with transparent background, -A = crop to artwork, -E300 = dpi.
gmt psconvert "${WORK}/midwest.ps" -TG -A -E300 -D"${OUT}" -Fmidwest

echo "Wrote ${OUT}/midwest.png"
ls -l "${OUT}/midwest.png"
