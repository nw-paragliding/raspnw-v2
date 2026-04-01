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

# scandir is at 0x081b1ea0, size 482
off = get_file_offset(0x081b1ea0, data)
chunk = data[off:off+482]
print("scandir implementation at 0x081b1ea0:")
for i in range(0, len(chunk), 16):
    hex_part = ' '.join(f'{b:02x}' for b in chunk[i:i+16])
    print(f"  0x{0x081b1ea0+i:08x}: {hex_part}")

# Look for calls FROM scandir (to opendir, getdents, readdir etc)
print("\nCalls from scandir:")
for i in range(len(chunk)-4):
    if chunk[i] == 0xe8:
        rel = struct.unpack_from('<i', chunk, i+1)[0]
        abs_addr = 0x081b1ea0 + i + 5 + rel
        print(f"  +0x{i:03x}: CALL 0x{abs_addr:08x}")

# Look for syscall-related patterns:
# int 0x80 = CD 80 (i386 syscall)
print("\nSyscall instructions (int 0x80 = CD 80):")
for i in range(len(chunk)-1):
    if chunk[i] == 0xcd and chunk[i+1] == 0x80:
        # What's in eax before? Look back 10 bytes for 'mov eax, N'
        context = chunk[max(0,i-15):i+3]
        print(f"  +0x{i:03x}: int 0x80, context: " + context.hex())
PYEOF
