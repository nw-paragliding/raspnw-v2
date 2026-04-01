#!/bin/bash
#
# run_uwpnw.sh
#
# Runs RASP soaring products using pre-computed WRF output from the
# University of Washington Atmospheric Sciences Lab (1.33km d4 PNW domain).
#
# Unlike the normal RASPNW pipeline (NAM → WRF → RASP), this script:
#   1. Stages UW's WRF wrfout NetCDF files (see stage_uw_wrfout.sh)
#   2. Runs only the RASP NCL post-processing stage (no WRF model run)
#
# DATA ACCESS: UW does not publish raw wrfout files via HTTP. Contact
#   ovens@atmos.washington.edu to request THREDDS/OPeNDAP or rsync access,
#   then configure stage_uw_wrfout.sh with the appropriate UW_DATA_METHOD.
#
# The RASP parameter files (rasp.run.parameters.UWPNW.*z) set:
#   LGETGRIB=0, LMODELINIT=0, LMODELRUN=1
# to skip GRIB download, WRF init, and wrf.exe respectively.
#
# Usage: run_uwpnw.sh INIT FCST_DAY
#   INIT     : initialization hour (0, 6, 12, or 18)
#   FCST_DAY : forecast day offset (0 = today)

if [ -z "$BASEDIR" ]; then
    echo "****Error: [RUN-UWPNW] BASEDIR variable not defined"
    exit 1
fi

if [ -z "$1" ]; then
    echo "****Error: [RUN-UWPNW] INIT argument not specified"
    exit 1
fi
INIT=$1
echo "[RUN-UWPNW] INITIALIZATION: ${INIT}z"
shift

if [ -z "$1" ]; then
    echo "****Error: [RUN-UWPNW] current+N argument not specified"
    exit 1
fi
N=$1
if [ "$N" == "0" ]; then
    N=""
    echo "[RUN-UWPNW] Forecast day: current"
else
    echo "[RUN-UWPNW] Forecast day: +${N}"
fi
shift

# UW only publishes 0z and 12z runs; skip other init times.
if [ "$INIT" != "0" ] && [ "$INIT" != "12" ]; then
    echo "[RUN-UWPNW] Skipping ${INIT}z - UW publishes 0z and 12z only"
    exit 0
fi

# Determine which RASP parameter file to use
PARAMFILE="$WXTOFLY_RUN/PARAMETERS/rasp.run.parameters.UWPNW${N:++$N}.${INIT}z"
if [ ! -f "$PARAMFILE" ]; then
    # Fall back to base init-time params if day-offset file doesn't exist
    PARAMFILE="$WXTOFLY_RUN/PARAMETERS/rasp.run.parameters.UWPNW.${INIT}z"
fi
if [ ! -f "$PARAMFILE" ]; then
    echo "****Error: [RUN-UWPNW] Parameter file not found: $PARAMFILE"
    exit 1
fi
echo "[RUN-UWPNW] Parameter file: $PARAMFILE"

# Step 1: Stage UW WRF output files into $BASEDIR/WRF/WRFV2/RASP/UWPNW/
echo "[RUN-UWPNW] Staging UW WRF output..."
$WXTOFLY_RUN/run_update_status.sh OK "[UWPNW] Staging UW WRF output for ${INIT}z"
if ! $WXTOFLY_UTIL/stage_uw_wrfout.sh "$INIT" "${N:-0}"; then
    echo "****Error: [RUN-UWPNW] UW WRF staging failed (see stage_uw_wrfout.sh)"
    $WXTOFLY_RUN/run_update_status.sh ERROR "[UWPNW] UW WRF staging failed"
    exit 1
fi
echo "[RUN-UWPNW] Staging complete"

# Step 2: Run RASP post-processing using downloaded wrfout files
# run_rasp.sh copies the parameter file and calls run.rasp UWPNW -M 0
# The parameter file overrides LMODELINIT=0 and LMODELRUN=1 so that
# RASP skips WRF init/run and goes straight to NCL plotting.
if ! $WXTOFLY_RUN/run_rasp.sh "UWPNW${N:++$N}" "$PARAMFILE"; then
    echo "****Error: [RUN-UWPNW] RASP post-processing failed"
    $WXTOFLY_RUN/run_update_status.sh ERROR "[UWPNW] RASP post-processing failed"
    exit 1
fi

echo "[RUN-UWPNW] Done"
