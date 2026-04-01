#!/bin/bash
SRCBASE=/Users/jameswillis/Code/raspnw-v2/model
LOCALBASE=/tmp/wxtofly

# Rebuild local directories (may have been cleaned)
mkdir -p ${LOCALBASE}/WRF/wrfsi/bin
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/cdl
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/log
mkdir -p ${LOCALBASE}/WRF/wrfsi/extdata/extprd

# Copy binary and domain files
cp ${SRCBASE}/WRF/wrfsi/bin/gridgen_model.exe ${LOCALBASE}/WRF/wrfsi/bin/
chmod +x ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe
cp -r ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/static/* ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/
cp -r ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/cdl/* ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/cdl/

# Symlink GEOG data
if [ ! -L ${LOCALBASE}/WRF/wrfsi/extdata/GEOG ]; then
    ln -s ${SRCBASE}/WRF/wrfsi/extdata/GEOG ${LOCALBASE}/WRF/wrfsi/extdata/GEOG
fi

# Test with wrfsi.d01 naming (from CDL filename convention)
echo "=== Creating wrfsi.d01 ==="
ncgen -o ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/wrfsi.d01 \
      ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/cdl/wrfsi.d01.cdl
echo "Created wrfsi.d01"

echo ""
echo "=== Running gridgen with MOAD_DATAROOT only ==="
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1

GCODE=$?
echo "Exit: $GCODE"

if [ $GCODE -ne 0 ] || grep -q "find_domain" /tmp/gridgen_out.txt 2>/dev/null; then
    echo ""
    echo "=== Also trying LAPS_DATA_ROOT ==="
    # Also try with LAPS_DATA_ROOT (not both!)
    LAPS_DATA_ROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
    INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
    ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1
fi
