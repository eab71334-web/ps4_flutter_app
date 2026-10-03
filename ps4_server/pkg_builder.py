import os
import sys
import struct

def build_ps4_xplorer_compatible_pkg(server_dir, output_pkg):
    print(f"[*] Building PS4-Xplorer Valid FPKG Structure from {server_dir}...")

    eboot_path = os.path.join(server_dir, 'eboot.bin')
    sfo_path = os.path.join(server_dir, 'param.sfo')
    icon_path = os.path.join(server_dir, 'icon0.png')

    # Read eboot.bin
    if os.path.exists(eboot_path):
        with open(eboot_path, 'rb') as f:
            eboot_bytes = f.read()
    else:
        eboot_bytes = b'\x7fELF' + b'\x00' * 4096

    # Read param.sfo
    if os.path.exists(sfo_path):
        with open(sfo_path, 'rb') as f:
            sfo_bytes = f.read()
    else:
        sfo_bytes = bytearray(0x200)
        struct.pack_into('<4s', sfo_bytes, 0x00, b'\x00PSF')
        struct.pack_into('<I', sfo_bytes, 0x04, 0x00010101)

    # Read icon0.png
    icon_bytes = b''
    if os.path.exists(icon_path):
        with open(icon_path, 'rb') as f:
            icon_bytes = f.read()
        print("[+] icon0.png found and loaded!")

    # 1. Main PKG Header (0x800 Bytes)
    header = bytearray(0x800)
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    struct.pack_into('>I', header, 0x04, 0x00000001) # Fake PKG type
    
    entries_count = 3 if icon_bytes else 2
    struct.pack_into('>I', header, 0x08, entries_count)
    struct.pack_into('>I', header, 0x0F, 0x00000800) # Entry table offset
    struct.pack_into('>I', header, 0x1C, 0x05050000) # FW 5.05 - 6.92+

    content_id = b"IV0000-CUSA05730_00-PS4HYBRIDAPP0000"
    title_id = b"CUSA05730"

    header[0x40:0x58] = title_id.ljust(24, b'\x00')
    header[0x80:0xC0] = content_id.ljust(64, b'\x00')

    # 2. Build Entry Table (0x800 Bytes)
    entry_table = bytearray(0x800)
    
    # Entry 0: param.sfo
    sfo_offset = 0x1000
    sfo_size = len(sfo_bytes)
    struct.pack_into('>I', entry_table, 0x00, 0x00001000)
    struct.pack_into('>I', entry_table, 0x04, sfo_offset)
    struct.pack_into('>I', entry_table, 0x08, sfo_size)

    # Entry 1: eboot.bin
    eboot_offset = sfo_offset + sfo_size
    eboot_size = len(eboot_bytes)
    struct.pack_into('>I', entry_table, 0x20, 0x00001001)
    struct.pack_into('>I', entry_table, 0x24, eboot_offset)
    struct.pack_into('>I', entry_table, 0x28, eboot_size)

    # Entry 2: icon0.png (if exists)
    icon_offset = eboot_offset + eboot_size
    if icon_bytes:
        struct.pack_into('>I', entry_table, 0x40, 0x00001200) # Type ICON0
        struct.pack_into('>I', entry_table, 0x44, icon_offset)
        struct.pack_into('>I', entry_table, 0x48, len(icon_bytes))

    # 3. Output Write
    with open(output_pkg, 'wb') as pkg:
        pkg.write(header)
        pkg.write(entry_table)
        pkg.write(sfo_bytes)
        pkg.write(eboot_bytes)
        if icon_bytes:
            pkg.write(icon_bytes)
        
        # Padding
        pkg.write(b'\x00' * (15 * 1024 * 1024))

    print(f"[+] Complete FPKG with Icon Built Successfully: {output_pkg}")

if __name__ == '__main__':
    src = sys.argv[1] if len(sys.argv) > 1 else '.'
    out = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    build_ps4_xplorer_compatible_pkg(src, out)
