#!/bin/bash
LOCALBASE=/tmp/wxtofly
STATICDIR=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static

# Create test files with different naming patterns
# Copy the NetCDF file with different names to test filter
cp ${STATICDIR}/static.01 ${STATICDIR}/static.01.nc      # with .nc extension
cp ${STATICDIR}/static.01 ${STATICDIR}/WAHRRR.nc         # sim name + .nc
cp ${STATICDIR}/static.01 ${STATICDIR}/WAHRRR            # just sim name
cp ${STATICDIR}/static.01 ${STATICDIR}/static.nest7grid  # LAPS convention
cp ${STATICDIR}/static.01 ${STATICDIR}/testfile          # simple lowercase no dot

echo "Files in static dir:"
ls ${STATICDIR}

echo ""
echo "=== Running gridgen ==="
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1

echo "Exit: $?"
