#!/bin/bash
LOCALBASE=/tmp/wxtofly

echo "=== Files in static dir ==="
ls -la ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/

echo ""
echo "=== Test: can we list the static.01 file? ==="
stat ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/static.01

echo ""
echo "=== Check gridgen env ==="
env | grep -E "MOAD|LAPS|INSTALL|LD_" | sort

echo ""
echo "=== Check if qemu-i386 can find the file via a simple test ==="
# Test that scandir issue isn't a qemu bug by trying to read via file(1)
file ${LOCALBASE}/WRF/wrfsi/domains/WAHRRR/static/static.01
