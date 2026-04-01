#!/bin/bash
BIN=/tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe

echo "=== Check objdump supports i386 ==="
objdump -i 2>/dev/null | grep -i "i386\|x86"

echo ""
echo "=== Try readelf for filter_non_numeric_fnames ==="
readelf -s ${BIN} 2>/dev/null | grep -i "filter\|scandir" | head -20

echo ""
echo "=== Try hexdump at filter address ==="
# Extract bytes at filter_non_numeric_fnames_ (0x080e5350)
# File offset = address - load_base + file_header_size
# For simple ELF: text section starts at 0x08048000 typically
python3 -c "
import struct, sys

with open('${BIN}', 'rb') as f:
    data = f.read()

# Find the address in the file
# The ELF load address for .text is typically at 0x08048000
# Filter is at 0x080e5350 
# offset in file = 0x080e5350 - 0x08048000 + sizeof(ELF headers)

# Let's just find the ELF program headers
magic = data[:4]
if magic != b'\x7fELF':
    print('Not ELF')
    sys.exit(1)

# ELF32 header
e_phoff = struct.unpack_from('<I', data, 28)[0]
e_phentsize = struct.unpack_from('<H', data, 42)[0]
e_phnum = struct.unpack_from('<H', data, 44)[0]

target_vaddr = 0x080e5350
for i in range(e_phnum):
    off = e_phoff + i * e_phentsize
    p_type = struct.unpack_from('<I', data, off)[0]
    p_offset = struct.unpack_from('<I', data, off+4)[0]
    p_vaddr = struct.unpack_from('<I', data, off+8)[0]
    p_filesz = struct.unpack_from('<I', data, off+16)[0]
    if p_type == 1 and p_vaddr <= target_vaddr < p_vaddr + p_filesz:
        file_offset = p_offset + (target_vaddr - p_vaddr)
        print(f'Target 0x{target_vaddr:08x} is at file offset 0x{file_offset:08x}')
        # Print 100 bytes as hex
        chunk = data[file_offset:file_offset+100]
        print('Hex: ' + chunk.hex())
        # Simple i386 decoder for common instructions
        break
" 2>&1
