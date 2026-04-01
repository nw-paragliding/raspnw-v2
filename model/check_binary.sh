#!/bin/bash
echo "=== file type ==="
file /tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe 2>/dev/null || echo "NOT FOUND - need to recreate /tmp/wxtofly"

echo ""
echo "=== glibc requirements ==="
objdump -p /tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe 2>/dev/null | grep -A1 NEEDED | head -20

echo ""
echo "=== check scandir behavior with simple C test ==="
cat > /tmp/test_scandir.c << 'CEOF'
#include <stdio.h>
#include <dirent.h>
#include <string.h>

int filter_all(const struct dirent *d) {
    printf("  filter called for: [%s] type=%d\n", d->d_name, (int)d->d_type);
    return 1; // accept all
}

int main(int argc, char *argv[]) {
    const char *path = argc > 1 ? argv[1] : ".";
    struct dirent **namelist;
    int n = scandir(path, &namelist, filter_all, alphasort);
    printf("scandir(%s) returned %d\n", path, n);
    return 0;
}
CEOF

# Compile 32-bit version
if gcc -m32 -o /tmp/test_scandir32 /tmp/test_scandir.c 2>/dev/null; then
    echo "Compiled 32-bit test binary"
    /tmp/test_scandir32 /tmp/wxtofly/WRF/wrfsi/domains/WAHRRR/static/ 2>&1
else
    echo "Could not compile 32-bit test (no 32-bit libc?)"
    # Try 64-bit
    gcc -o /tmp/test_scandir64 /tmp/test_scandir.c 2>/dev/null
    echo "=== 64-bit scandir test ==="
    /tmp/test_scandir64 /tmp/wxtofly/WRF/wrfsi/domains/WAHRRR/static/ 2>&1
fi
