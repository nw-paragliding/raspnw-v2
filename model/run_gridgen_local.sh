#!/bin/bash
# Run gridgen from Colima local filesystem to avoid 9P/virtiofs issues
SRCBASE=/Users/jameswillis/Code/raspnw-v2/model
LOCALBASE=/tmp/wxtofly

# Create local directory structure
mkdir -p ${LOCALBASE}/WRF/wrfsi/bin
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/cdl
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/log
mkdir -p ${LOCALBASE}/WRF/wrfsi/extdata/extprd

# Copy the binary (gridgen_model.exe)
cp ${SRCBASE}/WRF/wrfsi/bin/gridgen_model.exe ${LOCALBASE}/WRF/wrfsi/bin/
chmod +x ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe

# Copy domain static files
cp -r ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/static/* ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/
cp -r ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/cdl/* ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/cdl/

# Create symlink for GEOG data (keep on 9P since it's large)
ln -s ${SRCBASE}/WRF/wrfsi/extdata/GEOG ${LOCALBASE}/WRF/wrfsi/extdata/GEOG

# Update nest7grid.parms with local paths
sed "s|/Users/jameswillis/Code/raspnw-v2/model|${LOCALBASE}|g" \
  ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/static/nest7grid.parms > \
  ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/nest7grid.parms

# Update wrfsi.nl with local paths  
sed "s|/Users/jameswillis/Code/raspnw-v2/model|${SRCBASE}|g" \
  ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/static/wrfsi.nl > \
  ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/wrfsi.nl

echo "Running gridgen from local FS..."
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1

echo "Exit: $?"
echo "Static files generated:"
ls ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/
