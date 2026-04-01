#!/bin/bash
LOCALBASE=/tmp/wxtofly

echo "=== Running gridgen with sysroot in place ==="
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
strace -e trace=openat,open,getdents,getdents64,stat,statx,faccessat,newfstatat \
    -o /tmp/gridgen_sysroot_strace.txt \
    ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1

echo ""
echo "=== After getdents64 (sysroot trace) ==="
sed -n '/getdents64.*WAHRRR/,$ p' /tmp/gridgen_sysroot_strace.txt | head -30
