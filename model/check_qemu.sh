#!/bin/bash
echo "=== qemu-i386 version ==="
qemu-i386 --version

echo ""
echo "=== qemu-i386-static availability ==="
which qemu-i386-static 2>/dev/null || echo "not found"
ls /usr/bin/qemu-i386* 2>&1

echo ""
echo "=== binfmt registration ==="
cat /proc/sys/fs/binfmt_misc/qemu-i386

echo ""
echo "=== Test with explicit qemu-i386 invocation (no binfmt) ==="
MOAD_DATAROOT=/tmp/wxtofly/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=/tmp/wxtofly/WRF/wrfsi \
qemu-i386 /tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe 2>&1 | head -15
