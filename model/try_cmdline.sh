#!/bin/bash
SRCBASE=/Users/jameswillis/Code/raspnw-v2/model
LOCALBASE=/tmp/wxtofly

# Ensure directories exist
mkdir -p ${LOCALBASE}/WRF/wrfsi/bin
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/cdl
mkdir -p ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/log
mkdir -p ${LOCALBASE}/WRF/wrfsi/extdata/extprd
cp ${SRCBASE}/WRF/wrfsi/bin/gridgen_model.exe ${LOCALBASE}/WRF/wrfsi/bin/
chmod +x ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe
cp -r ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/static/* ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/
cp -r ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/cdl/* ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/cdl/ 2>/dev/null
[ ! -L ${LOCALBASE}/WRF/wrfsi/extdata/GEOG ] && \
    ln -s ${SRCBASE}/WRF/wrfsi/extdata/GEOG ${LOCALBASE}/WRF/wrfsi/extdata/GEOG
ncgen -o ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/wrfsi.d01 \
      ${SRCBASE}/WRF/wrfsi/domains/WAHRRR/cdl/wrfsi.d01.cdl 2>/dev/null

echo "=== Test 1: Command line dataroot ==="
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR 2>&1 | head -15

echo ""
echo "=== Test 2: Strace ALL syscalls ==="
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
strace -e 'trace=all' \
    -o /tmp/gridgen_full_strace.txt \
    ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1 | head -10

echo ""
echo "=== Strace around scandir/filter ==="
grep -E "scandir|getdents|open.*static|read.*static" /tmp/gridgen_full_strace.txt | head -20

echo ""
echo "=== Strace: all getdents calls ==="
grep -E "getdents|WAHRRR" /tmp/gridgen_full_strace.txt | head -20
