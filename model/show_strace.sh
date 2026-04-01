#!/bin/bash
echo "=== Full strace (after getdents64) ==="
# Find the getdents64 line number and show 50 lines after it
grep -n "getdents64.*WAHRRR" /tmp/gridgen_full_strace.txt | head -3
echo ""
# Show everything from getdents64 onwards
sed -n '/getdents64.*WAHRRR/,$ p' /tmp/gridgen_full_strace.txt | head -60
