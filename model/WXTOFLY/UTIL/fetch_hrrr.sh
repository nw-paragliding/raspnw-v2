#!/bin/bash
#
# fetch_hrrr.sh
#
# Downloads HRRR wrfprs GRIB2 files from NOMADS for a given init time.
# Use this to stage HRRR data before running the WAHRRR RASP pipeline,
# or as a standalone connectivity/availability test.
#
# NOMADS path:
#   https://nomads.ncep.noaa.gov/pub/data/nccf/com/hrrr/prod/
#   hrrr.YYYYMMDD/conus/hrrr.tHHz.wrfprsf[FH].grib2
#
# Usage: fetch_hrrr.sh [INIT_HOUR] [FCST_DAY] [START_FH] [END_FH]
#   INIT_HOUR : init hour, 0 or 18 (default: 0)
#   FCST_DAY  : day offset from today for the init date (default: 0 = today)
#   START_FH  : first forecast hour to fetch (default: 39 for +1 day soaring)
#   END_FH    : last forecast hour to fetch  (default: 48)
#
# Examples:
#   fetch_hrrr.sh              # today 0z, hours 39-48 (tomorrow's soaring)
#   fetch_hrrr.sh 0 0 15 27    # today 0z, hours 15-27 (today's soaring)
#   fetch_hrrr.sh 18 0 0 12    # today 18z, hours 0-12

set -e

NOMADS_BASE="https://nomads.ncep.noaa.gov/pub/data/nccf/com/hrrr/prod"

INIT_HOUR=${1:-0}
FCST_DAY=${2:-0}
START_FH=${3:-39}
END_FH=${4:-48}

# Compute target date (macOS and Linux compatible)
TARGET_DATE=$(date -v+${FCST_DAY}d +%Y%m%d 2>/dev/null \
    || date -d "+${FCST_DAY} days" +%Y%m%d)
INIT_HH=$(printf "%02d" "$INIT_HOUR")

OUTPUT_DIR="$(dirname "$0")/../../RASP/RUN/HRRR/GRIB"
mkdir -p "$OUTPUT_DIR"

echo "============================================================"
echo "  HRRR fetch: ${TARGET_DATE} ${INIT_HH}z  hours ${START_FH}-${END_FH}"
echo "  Output: $OUTPUT_DIR"
echo "============================================================"

# Check curl is available
if ! command -v curl &>/dev/null; then
    echo "****Error: curl not found"
    exit 1
fi

DOWNLOADED=0
FAILED=0

for FH in $(seq "$START_FH" "$END_FH"); do
    FH_PAD=$(printf "%02d" "$FH")
    FILENAME="hrrr.t${INIT_HH}z.wrfprsf${FH_PAD}.grib2"
    URL="${NOMADS_BASE}/hrrr.${TARGET_DATE}/conus/${FILENAME}"
    DEST="${OUTPUT_DIR}/${FILENAME}"

    printf "  [+%02dh] %s ... " "$FH" "$FILENAME"

    HTTP_CODE=$(curl --silent --show-error --fail \
        --retry 3 --retry-delay 5 \
        --connect-timeout 15 --max-time 300 \
        --write-out "%{http_code}" \
        -o "$DEST" "$URL" 2>&1) || true

    if [ -f "$DEST" ] && [ -s "$DEST" ]; then
        SIZE=$(du -h "$DEST" | cut -f1)
        echo "OK (${SIZE})"
        DOWNLOADED=$((DOWNLOADED + 1))
    else
        echo "FAILED (HTTP ${HTTP_CODE})"
        rm -f "$DEST"
        FAILED=$((FAILED + 1))
    fi
done

echo ""
echo "  Downloaded: ${DOWNLOADED}  Failed: ${FAILED}"

if [ "$FAILED" -gt 0 ]; then
    echo ""
    echo "  Note: HRRR 0z extended run (hours >18) is available ~03:00 UTC."
    echo "  If fetching hours >18, ensure the run has completed on NOMADS."
fi

# Check for cnvgrib (needed for GRIB2->GRIB1 conversion in rasp.pl)
echo ""
echo "  Checking for cnvgrib ..."
CNVGRIB=$(find "$( [ -n "$BASEDIR" ] && echo "$BASEDIR/UTIL" || echo "." )" \
    -name "cnvgrib" -type f 2>/dev/null | head -1)
if [ -n "$CNVGRIB" ]; then
    echo "  cnvgrib found: $CNVGRIB"
else
    echo "  cnvgrib NOT found in BASEDIR/UTIL."
    echo "  Checking PATH ..."
    if command -v cnvgrib &>/dev/null; then
        echo "  cnvgrib found in PATH: $(command -v cnvgrib)"
    else
        echo "  ****Warning: cnvgrib not found. GRIB2->GRIB1 conversion will fail."
        echo "  Install from: https://www.nco.ncep.noaa.gov/pmb/docs/libs/cnvgrib/"
        echo "  Or via conda:  conda install -c conda-forge wgrib2"
    fi
fi

echo ""
echo "Done."
