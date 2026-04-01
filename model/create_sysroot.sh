#!/bin/bash
# Create qemu-i386 sysroot so path lookups work correctly
# qemu-i386 prepends /usr/gnemul/qemu-i386 to absolute paths

SYSROOT=/usr/gnemul/qemu-i386
LOCALBASE=/tmp/wxtofly

echo "=== Creating qemu-i386 sysroot symlinks ==="
sudo mkdir -p ${SYSROOT}/tmp
sudo mkdir -p ${SYSROOT}/proc
# Symlink /tmp so qemu-i386 finds our WAHRRR static dir
sudo ln -sfn /tmp/wxtofly ${SYSROOT}/tmp/wxtofly 2>/dev/null || true

echo ""
echo "=== Check if sysroot helps ==="
ls -la ${SYSROOT}/tmp/wxtofly/WRF/wrfsi/domains/WAHRRR/static/ 2>/dev/null | head -5 || echo "path not accessible via sysroot"

echo ""
echo "=== Verify binfmt qemu-i386 is registered ==="
cat /proc/sys/fs/binfmt_misc/qemu-i386 2>/dev/null || echo "qemu-i386 not registered"
