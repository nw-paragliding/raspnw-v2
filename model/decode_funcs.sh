#!/bin/bash
BIN=/tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe

python3 << 'PYEOF'
import struct, sys

with open('/tmp/wxtofly/WRF/wrfsi/bin/gridgen_model.exe', 'rb') as f:
    data = f.read()

def get_file_offset(vaddr, data):
    e_phoff = struct.unpack_from('<I', data, 28)[0]
    e_phentsize = struct.unpack_from('<H', data, 42)[0]
    e_phnum = struct.unpack_from('<H', data, 44)[0]
    for i in range(e_phnum):
        off = e_phoff + i * e_phentsize
        p_type = struct.unpack_from('<I', data, off)[0]
        p_offset = struct.unpack_from('<I', data, off+4)[0]
        p_vaddr = struct.unpack_from('<I', data, off+8)[0]
        p_filesz = struct.unpack_from('<I', data, off+16)[0]
        if p_type == 1 and p_vaddr <= vaddr < p_vaddr + p_filesz:
            return p_offset + (vaddr - p_vaddr)
    return None

# find_domain_name_ is at 0x080d2130, size = 0x080d2b53 - 0x080d2130 = 0xa23
off = get_file_offset(0x080d2130, data)
chunk = data[off:off+0xa23]
print(f"find_domain_name_ at file offset 0x{off:08x}, size {len(chunk)} bytes")
print("First 200 bytes hex: " + chunk[:200].hex())

# Find references to scandir (0x081b1ea0)
# In i386, call rel32: e8 followed by relative offset
# scandir is at 0x081b1ea0
# A call to scandir from address X would be: e8 <0x081b1ea0 - X - 5>
for i in range(len(chunk)-4):
    if chunk[i] == 0xe8:
        rel = struct.unpack_from('<i', chunk, i+1)[0]
        abs_addr = 0x080d2130 + i + 5 + rel
        if abs_addr == 0x081b1ea0:
            print(f"  CALL to scandir at offset +0x{i:x} (vaddr 0x{0x080d2130+i:08x})")
            # Show the 20 bytes before this call to see what was pushed (filter arg)
            print(f"  Context (preceding bytes): " + chunk[max(0,i-30):i+5].hex())
            break
PYEOF
