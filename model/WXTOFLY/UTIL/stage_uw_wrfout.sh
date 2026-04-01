#!/bin/bash
#
# stage_uw_wrfout.sh
#
# Stages UW Atmospheric Sciences Lab WRF wrfout files for RASP post-processing.
#
# UW runs WRF-ARW v4.1.3 twice daily (0z and 12z) with a 1.33km d4 domain
# covering WA, OR, western ID, and the extreme southern ~50km of BC — the
# same coverage area as our PNWRAT/PNW domains.
#
# ---- DATA ACCESS STATUS ------------------------------------------------
#
# UW's raw wrfout NetCDF files are NOT publicly accessible via HTTP.
# Their web interface (a.atmos.washington.edu/wrfrt/) serves only pre-rendered
# GIF images and CGI-generated soundings/meteograms from server-side files.
#
# To use this pipeline, request data access from the UW Atmos group:
#   Contact: David Ovens  <ovens@atmos.washington.edu>
#            Cliff Mass   <cliff@atmos.washington.edu>
#   Ask for: THREDDS/OPeNDAP endpoint or direct rsync/FTP access to
#            d4 wrfout NetCDF files from their operational WRF-GFS runs
#
# Once access is granted, update UW_DATA_METHOD and the relevant
# section below to pull files to $DEST_DIR.
#
# ---- EXPECTED FILE FORMAT ----------------------------------------------
#
# UW wrfout files follow standard WRF-ARW NetCDF naming:
#   wrfout_d04_YYYY-MM-DD_HH:00:00
#
# This script renames them as wrfout_d01_* for the UWPNW region
# (UWPNW has only one domain — UW's d4 is our d01).
#
# ---- DOMAIN INFO -------------------------------------------------------
#
# UW d4 grid (from dec22.namelist.wps):
#   Projection : Lambert conformal  truelat1=30  truelat2=60  stand_lon=-121
#   Center     : 45.664N, 134.742W  (outer domain ref — d4 offset within that)
#   Grid size  : 925 x 664 points at 1.33km
#   Coverage   : WA, OR, western ID, extreme southern BC (~50km)
#
# Usage: stage_uw_wrfout.sh INIT_HOUR [FCST_DAY]
#   INIT_HOUR : 0 or 12  (UW publishes only 0z and 12z runs)
#   FCST_DAY  : day offset from today (default 0 = today)

if [ -z "$BASEDIR" ]; then
    echo "****Error: [UW-STAGE] BASEDIR not defined"
    exit 1
fi

INIT_HOUR=${1:-0}
FCST_DAY=${2:-0}

if [ "$INIT_HOUR" != "0" ] && [ "$INIT_HOUR" != "12" ]; then
    echo "****Error: [UW-STAGE] INIT_HOUR must be 0 or 12 (UW publishes only those runs)"
    exit 1
fi

TARGET_DATE=$(date -d "+${FCST_DAY} days" +%Y%m%d 2>/dev/null \
    || date -v+${FCST_DAY}d +%Y%m%d)
INIT_HH=$(printf "%02d" "$INIT_HOUR")
RUN_ID="${TARGET_DATE}${INIT_HH}"

DEST_DIR="$BASEDIR/WRF/WRFV2/RASP/UWPNW"
mkdir -p "$DEST_DIR"
rm -f "$DEST_DIR"/wrfout_d0*

echo "[UW-STAGE] Staging UW d4 wrfout files for run ${RUN_ID} into $DEST_DIR"

# ---- Choose data access method -----------------------------------------
# Set UW_DATA_METHOD to one of: THREDDS | RSYNC | SCP | LOCAL
# Update the corresponding section below once UW grants access.
#
UW_DATA_METHOD="PENDING"

case "$UW_DATA_METHOD" in

    THREDDS)
        # Example: OPeNDAP access via UW THREDDS catalog
        # TODO: Replace with actual THREDDS base URL provided by UW
        UW_THREDDS_BASE="https://thredds.atmos.washington.edu/thredds/fileServer"  # placeholder
        UW_CATALOG_PATH="wrfrt/gfs/${RUN_ID}"  # placeholder — confirm with UW
        UW_DOMAIN="d04"
        for HH in $(seq -w 0 60); do
            FCST_DATETIME="${TARGET_DATE:0:4}-${TARGET_DATE:4:2}-${TARGET_DATE:6:2}_${INIT_HH}:00:00"
            FCST_DATETIME=$(date -d "${TARGET_DATE} ${INIT_HH}:00 + ${HH} hours" \
                +"%Y-%m-%d_%H:%M:%S" 2>/dev/null)
            SRC="${UW_THREDDS_BASE}/${UW_CATALOG_PATH}/wrfout_${UW_DOMAIN}_${FCST_DATETIME}"
            DEST="${DEST_DIR}/wrfout_d01_${FCST_DATETIME}"
            curl --silent --show-error --fail --retry 3 --retry-delay 10 \
                 --connect-timeout 30 --max-time 600 \
                 -o "$DEST" "$SRC" || echo "****Warning: [UW-STAGE] Failed: $SRC"
        done
        ;;

    RSYNC)
        # Example: rsync from UW server (requires SSH key or credentials)
        UW_RSYNC_HOST="placeholder.atmos.washington.edu"  # TODO: confirm with UW
        UW_RSYNC_PATH="/data/wrf/gfs/${RUN_ID}/wrfout_d04_*"  # placeholder
        rsync -avz "${UW_RSYNC_HOST}:${UW_RSYNC_PATH}" "${DEST_DIR}/" || {
            echo "****Error: [UW-STAGE] rsync failed"
            exit 1
        }
        # Rename d04 → d01
        for f in "$DEST_DIR"/wrfout_d04_*; do
            mv "$f" "${f/wrfout_d04_/wrfout_d01_}"
        done
        ;;

    SCP)
        # Example: scp from UW server
        UW_SCP_HOST="placeholder.atmos.washington.edu"  # TODO: confirm with UW
        UW_SCP_PATH="/data/wrf/gfs/${RUN_ID}/"  # placeholder
        scp "${UW_SCP_HOST}:${UW_SCP_PATH}wrfout_d04_*" "${DEST_DIR}/" || {
            echo "****Error: [UW-STAGE] scp failed"
            exit 1
        }
        for f in "$DEST_DIR"/wrfout_d04_*; do
            mv "$f" "${f/wrfout_d04_/wrfout_d01_}"
        done
        ;;

    LOCAL)
        # Example: data already mounted or copied locally
        UW_LOCAL_PATH="/mnt/uw-wrf/${RUN_ID}"  # TODO: update to actual mount point
        cp "${UW_LOCAL_PATH}"/wrfout_d04_* "${DEST_DIR}/" || {
            echo "****Error: [UW-STAGE] local copy failed — is $UW_LOCAL_PATH mounted?"
            exit 1
        }
        for f in "$DEST_DIR"/wrfout_d04_*; do
            mv "$f" "${f/wrfout_d04_/wrfout_d01_}"
        done
        ;;

    PENDING)
        echo "****Error: [UW-STAGE] Data access not yet configured."
        echo "  Contact ovens@atmos.washington.edu or cliff@atmos.washington.edu"
        echo "  to request THREDDS/OPeNDAP or rsync access to d4 wrfout files."
        echo "  Then set UW_DATA_METHOD in this script and fill in the credentials."
        exit 1
        ;;

    *)
        echo "****Error: [UW-STAGE] Unknown UW_DATA_METHOD: $UW_DATA_METHOD"
        exit 1
        ;;
esac

# Verify we staged something usable
D01_COUNT=$(ls "$DEST_DIR"/wrfout_d01_* 2>/dev/null | wc -l)
if [ "$D01_COUNT" -eq 0 ]; then
    echo "****Error: [UW-STAGE] No wrfout_d01 files found in $DEST_DIR after staging"
    exit 1
fi
echo "[UW-STAGE] Staged ${D01_COUNT} wrfout_d01 file(s) for run ${RUN_ID}"
