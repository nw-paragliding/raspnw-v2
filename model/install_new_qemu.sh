#!/bin/bash
echo "=== Current qemu version ==="
dpkg -l qemu-user 2>/dev/null | tail -1
dpkg -l qemu-user-static 2>/dev/null | tail -1

echo ""
echo "=== Install newer qemu-user-static ==="
sudo apt-get install -y qemu-user-static 2>&1 | tail -5

echo ""
echo "=== New versions ==="
dpkg -l qemu-user 2>/dev/null | tail -1
dpkg -l qemu-user-static 2>/dev/null | tail -1
ls /usr/bin/qemu-i386*

echo ""
echo "=== Test qemu-i386-static ==="
MOAD_DATAROOT=/tmp/wxtofly/WRF/wrfsi/domains/WAHRRR \
INSTALLROOT=/tmp/wxtofly/WRF/wrfsi \
qemu-i386-static /tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe 2>&1 | head -15
