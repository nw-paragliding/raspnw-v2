#!/bin/bash
LOCALBASE=/tmp/wxtofly

# Check if strace available
if ! command -v strace &>/dev/null; then
    echo "Installing strace..."
    sudo apt-get install -y strace 2>&1 | tail -3
fi

echo "=== Running gridgen under strace ==="
MOAD_DATAROOT=${LOCALBASE}/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=${LOCALBASE}/WRF/wrfsi \
strace -e trace=openat,open,getdents,getdents64,stat,statx,read,readlink \
    -o /tmp/gridgen_strace.txt \
    ${LOCALBASE}/WRF/wrfsi/bin/gridgen_model.exe 2>&1

echo ""
echo "=== strace around scandir ==="
grep -A5 -B5 "WAHRRR/static" /tmp/gridgen_strace.txt | head -80
