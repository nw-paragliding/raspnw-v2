#!/bin/bash
LOCALBASE=/tmp/wxtofly

echo "=== Run gridgen with qemu -strace (guest syscall view) ==="
# qemu-i386 has its own -strace that shows guest syscalls from i386 perspective
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
qemu-i386 -strace ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1 | grep -E "getdents|readdir|open.*static|scandir" | head -20

echo ""
echo "=== qemu-i386 -strace full output for first 60 lines ==="
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
qemu-i386 -strace ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1 | head -60
