#!/bin/bash
echo "=== Install objdump for i386 ==="
sudo apt-get install -y binutils 2>&1 | grep -E "^(Setting up|Processing)" | head -3

echo ""
echo "=== Find filter_filenames in binary ==="
# Get the address of filter_filenames_  
objdump -D -M i386,intel -m i386 /tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe 2>/dev/null | \
    grep -B2 -A50 "filter_filenames" | head -80 || \
    echo "filter_filenames not found as symbol"

echo ""
echo "=== Try with nm ==="
nm /tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe 2>/dev/null | grep -i "filter\|scandir\|domain_name" | head -20

echo ""
echo "=== Find scandir calls ==="
objdump -D -M i386,intel -m i386 /tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe 2>/dev/null | \
    grep -B5 -A2 "scandir" | head -40
