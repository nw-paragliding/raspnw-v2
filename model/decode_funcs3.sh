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

# Build symbol table from nm output
symbols = {
    0x080beddc: '__filter_string_END',
    0x080e5771: '__filter_non_numeric_fnames_END',
    0x080f60be: '__filter_2dx_END',
    0x080d2b53: '__find_domain_name_END',
    0x080f4130: 'filter_2dx_',
    0x080e5350: 'filter_non_numeric_fnames_',
    0x080beda0: 'filter_string_',
    0x080d2130: 'find_domain_name_',
    0x081b1ea0: 'scandir',
}

# find_domain_name_: 0x080d2130 - 0x080d2b53
off_fd = get_file_offset(0x080d2130, data)
size_fd = 0x080d2b53 - 0x080d2130
chunk_fd = data[off_fd:off_fd+size_fd]

print("ALL calls from find_domain_name_:")
for i in range(len(chunk_fd)-4):
    if chunk_fd[i] == 0xe8:
        rel = struct.unpack_from('<i', chunk_fd, i+1)[0]
        abs_addr = 0x080d2130 + i + 5 + rel
        name = symbols.get(abs_addr, f'0x{abs_addr:08x}')
        print(f"  +0x{i:03x}: CALL {name}")
        if 'scandir' in name or 'filter' in name.lower():
            print(f"    Context: " + chunk_fd[max(0,i-20):i+5].hex())
PYEOF
