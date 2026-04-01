#!/bin/bash
set -e
SRCBASE=/Users/jameswillis/Code/raspnw-v2/model
LOCALBASE=/tmp/wxtofly

echo "=== Creating NetCDF template from CDL (as static.01) ==="
ncgen -o ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/static.01 \
      ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/cdl/wrfsi.d01.cdl
echo "Created static.01:"
ls -lh ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/static.01

echo ""
echo "=== Running gridgen ==="
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1

GCODE=$?
echo "gridgen exit code: $GCODE"

echo ""
echo "Static dir contents:"
ls -lh ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/

if [ $GCODE -eq 0 ]; then
    echo ""
    echo "=== Copying static.01 back to host ==="
    cp ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/static.01 \
       ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/static/static.01
    echo "Done."
fi
