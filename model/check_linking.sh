#!/bin/bash
BIN=/tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe

echo "=== File type ==="
file ${BIN}

echo ""
echo "=== Dynamic dependencies ==="
readelf -d ${BIN} 2>/dev/null | grep -E "NEEDED|SONAME|INTERP" | head -10

echo ""
echo "=== Section headers (check for .dynamic) ==="
readelf -S ${BIN} 2>/dev/null | grep -E "dynamic|plt|got" | head -10

echo ""
echo "=== PT_INTERP (dynamic linker) ==="
readelf -l ${BIN} 2>/dev/null | grep -i "interp\|dynamic" | head -5

echo ""
echo "=== Check scandir GOT/PLT entry ==="
# If dynamically linked, scandir would be in PLT
# grep for scandir in dynamic symbol table
readelf --dyn-syms ${BIN} 2>/dev/null | grep -i scandir | head -5
