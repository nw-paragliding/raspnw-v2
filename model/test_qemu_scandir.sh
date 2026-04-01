#!/bin/bash
set -e
echo "=== Installing build tools ==="
sudo apt-get install -y gcc 2>&1 | tail -3

echo ""
echo "=== Compile 64-bit test ==="
cat > /tmp/test_scandir.c << 'CEOF'
#include <stdio.h>
#include <dirent.h>
#include <string.h>
#include <stdlib.h>
int count = 0;
int accept_all(const struct dirent *d) {
    printf("  filter[%d]: name=[%s]\n", count++, d->d_name);
    fflush(stdout);
    if (d->d_name[0] == '.') return 0;
    return 1;
}
int main(int argc, char *argv[]) {
    const char *path = argc > 1 ? argv[1] : "/tmp";
    struct dirent **namelist;
    printf("Calling scandir(%s)\n", path);
    int n = scandir(path, &namelist, accept_all, alphasort);
    printf("scandir returned n=%d\n", n);
    return 0;
}
CEOF

gcc -o /tmp/test_scandir64 /tmp/test_scandir.c && echo "Compiled 64-bit"

echo ""
echo "=== 64-bit scandir (baseline) ==="
/tmp/test_scandir64 /tmp/wxtofly/WRF/wrfsi/domains/WAHRRR/static/
