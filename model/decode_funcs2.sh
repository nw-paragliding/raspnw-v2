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

# find_domain_name_ is at 0x080d2130, size = 0xa23
off_fd = get_file_offset(0x080d2130, data)
chunk_fd = data[off_fd:off_fd+0xa23]

targets = {
    'filter_non_numeric_fnames_': 0x080e5350,
    'scandir': 0x081b1ea0,
}

print("Calls from find_domain_name_:")
for i in range(len(chunk_fd)-4):
    if chunk_fd[i] == 0xe8:
        rel = struct.unpack_from('<i', chunk_fd, i+1)[0]
        abs_addr = 0x080d2130 + i + 5 + rel
        name = next((n for n, a in targets.items() if a == abs_addr), None)
        if name:
            print(f"  +0x{i:x}: CALL {name} (0x{abs_addr:08x})")
            print(f"    Context: " + chunk_fd[max(0,i-20):i+5].hex())

# Now look at filter_non_numeric_fnames_ for scandir call
print("\nCalls from filter_non_numeric_fnames_:")
off_fn = get_file_offset(0x080e5350, data)
size_fn = 0x080e5771 - 0x080e5350
chunk_fn = data[off_fn:off_fn+size_fn]

for i in range(len(chunk_fn)-4):
    if chunk_fn[i] == 0xe8:
        rel = struct.unpack_from('<i', chunk_fn, i+1)[0]
        abs_addr = 0x080e5350 + i + 5 + rel
        name = next((n for n, a in targets.items() if a == abs_addr), None)
        if name:
            print(f"  +0x{i:x}: CALL {name} (0x{abs_addr:08x})")
            print(f"    Context: " + chunk_fn[max(0,i-30):i+5].hex())
        elif abs_addr >= 0x08048000 and abs_addr < 0x09000000:
            print(f"  +0x{i:x}: CALL 0x{abs_addr:08x} (unknown)")

# Print first 100 bytes of filter_non_numeric_fnames_
print("\nfirst 100 bytes of filter_non_numeric_fnames_:")
print(chunk_fn[:100].hex())
PYEOF
