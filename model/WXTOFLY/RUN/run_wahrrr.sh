#!/bin/bash
#
# run_wahrrr.sh
#
# Runs RASP soaring products using HRRR 3km GRIB2 data from NOMADS for
# Washington state (WAHRRR domain, single 3km domain centered on WA).
#
# HRRR runs every hour; only 0z and 18z extended runs (48h) are used here
# since they provide sufficient forecast range to cover the WA soaring day.
#
# NOMADS data path:
#   https://nomads.ncep.noaa.gov/pub/data/nccf/com/hrrr/prod/hrrr.YYYYMMDD/conus/
#   hrrr.tHHz.wrfprsf[FH].grib2  (FH = 2-digit forecast hour)
#
# GRIB2 -> GRIB1 conversion via cnvgrib is handled in rasp.pl before grib_prep.
#
# Usage: run_wahrrr.sh INIT FCST_DAY
#   INIT     : initialization hour (0 or 18)
#   FCST_DAY : forecast day offset (0 = today)

if [ -z "$BASEDIR" ]; then
    echo "****Error: [RUN-WAHRRR] BASEDIR variable not defined"
    exit 1
fi

if [ -z "$1" ]; then
    echo "****Error: [RUN-WAHRRR] INIT argument not specified"
    exit 1
fi
INIT=$1
echo "[RUN-WAHRRR] INITIALIZATION: ${INIT}z"
shift

if [ -z "$1" ]; then
    echo "****Error: [RUN-WAHRRR] current+N argument not specified"
    exit 1
fi
N=$1
if [ "$N" == "0" ]; then
    N=""
    echo "[RUN-WAHRRR] Forecast day: current"
else
    N="+$N"
    echo "[RUN-WAHRRR] Forecast day: $N"
fi
shift

# Only 0z and 18z extended HRRR runs are used; skip others.
if [ "$INIT" != "0" ] && [ "$INIT" != "18" ]; then
    echo "[RUN-WAHRRR] Skipping ${INIT}z - only 0z and 18z runs configured"
    exit 0
fi

PARAMFILE="$WXTOFLY_RUN/PARAMETERS/rasp.run.parameters.WAHRRR${N}.${INIT}z"
if [ ! -f "$PARAMFILE" ]; then
    PARAMFILE="$WXTOFLY_RUN/PARAMETERS/rasp.run.parameters.WAHRRR.${INIT}z"
fi
if [ ! -f "$PARAMFILE" ]; then
    echo "****Error: [RUN-WAHRRR] Parameter file not found: $PARAMFILE"
    exit 1
fi
echo "[RUN-WAHRRR] Parameter file: $PARAMFILE"

if $WXTOFLY_RUN/run_rasp.sh "WAHRRR${N}" "$PARAMFILE"; then
    $WXTOFLY_RUN/run_background_task.sh $WXTOFLY_RUN/run_tasks_d2.sh "WAHRRR${N}"
else
    echo "****Error: [RUN-WAHRRR] RASP run failed"
    $WXTOFLY_RUN/run_update_status.sh ERROR "[WAHRRR] RASP run failed"
    exit 1
fi

echo "[RUN-WAHRRR] Done"
