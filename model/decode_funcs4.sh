#!/bin/bash
python3 << 'PYEOF'
import struct

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

# Look at find_domain_name_ starting at the scandir-related call (+0xf0 context, call at +0x100)
off_fd = get_file_offset(0x080d2130, data)
# Show bytes from +0x0d0 to +0x150 to see full context of call at +0x100
chunk = data[off_fd+0x0d0:off_fd+0x150]
print("Context of call at +0x100 (bytes 0x0d0 to 0x150):")
for i in range(0, len(chunk), 16):
    hex_part = ' '.join(f'{b:02x}' for b in chunk[i:i+16])
    print(f"  +0x{0x0d0+i:03x}: {hex_part}")

# Look at what's at 0x080e5790 (the unknown function called)
off_fn = get_file_offset(0x080e5790, data)
chunk_fn = data[off_fn:off_fn+100]
print("\nBytes at 0x080e5790 (unknown function):")
for i in range(0, len(chunk_fn), 16):
    hex_part = ' '.join(f'{b:02x}' for b in chunk_fn[i:i+16])
    print(f"  +0x{i:03x}: {hex_part}")

# Find any references to scandir (0x081b1ea0) in the area after filter_non_numeric_fnames_
# (0x080e5771 to 0x080f4130)
off_area = get_file_offset(0x080e5771, data)
size_area = 0x080f4130 - 0x080e5771
chunk_area = data[off_area:off_area+size_area]
print(f"\nLooking for scandir calls in 0x080e5771-0x080f4130:")
for i in range(len(chunk_area)-4):
    if chunk_area[i] == 0xe8:
        rel = struct.unpack_from('<i', chunk_area, i+1)[0]
        abs_addr = 0x080e5771 + i + 5 + rel
        if abs_addr == 0x081b1ea0:
            vaddr = 0x080e5771 + i
            print(f"  Found scandir call at 0x{vaddr:08x}")
            print(f"  Context: " + chunk_area[max(0,i-30):i+5].hex())
PYEOF
