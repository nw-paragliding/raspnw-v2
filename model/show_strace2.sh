#!/bin/bash
wc -l /tmp/gridgen_full_strace.txt
echo "=== Last 40 lines of strace ==="
tail -40 /tmp/gridgen_full_strace.txt
echo ""
echo "=== All faccessat calls ==="
grep "faccessat" /tmp/gridgen_full_strace.txt | head -20
echo ""
echo "=== Line count around getdents ==="
grep -n "getdents" /tmp/gridgen_full_strace.txt
