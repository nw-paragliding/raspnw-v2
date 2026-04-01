#!/bin/bash
BIN=/tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe

echo "=== filter_non_numeric_fnames_ (0x080e5350 - 0x080e5771) ==="
objdump -d --start-address=0x080e5350 --stop-address=0x080e5771 \
    -M i386,intel -m i386 ${BIN} 2>/dev/null | head -80

echo ""
echo "=== find_domain_name_ scandir call area ==="
objdump -d --start-address=0x080d2130 --stop-address=0x080d2b53 \
    -M i386,intel -m i386 ${BIN} 2>/dev/null | grep -A20 "scandir" | head -40
