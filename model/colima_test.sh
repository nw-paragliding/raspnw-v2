#!/bin/bash
echo "Testing binfmt for i386..."
cp /Users/jameswillis/Code/raspnw-v2/model/WRF/wrfsi/bin/gridgen_model.exe /tmp/ggm_test 2>&1
chmod +x /tmp/ggm_test
echo "Binary info:"
dd if=/tmp/ggm_test bs=1 count=20 2>/dev/null | xxd
echo "Attempting exec..."
/tmp/ggm_test 2>&1 | head -5 || echo "exec failed with: $?"
