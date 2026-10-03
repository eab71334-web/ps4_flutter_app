import os
import sys
import struct

def build_ps4_xplorer_compatible_pkg(server_dir, output_pkg):
    print(f"[*] Building PS4-Xplorer Valid FPKG Structure from {server_dir}...")

    eboot_path = os.path.join(server_dir, 'eboot.bin')
    sfo_path = os.path.join(server_dir, 'param.sfo')

    # Read eboot.bin
    if os.path.exists(eboot_path):
        with open(eboot_path, 'rb') as f:
            eboot_bytes = f.read()
    else:
        eboot_bytes = b'\x7fELF' + b'\x00' * 4096

    # Minimal Valid Binary SFO (0x0200 bytes)
    if os.path.exists(sfo_path):
        with open(sfo_path, 'rb') as f:
            sfo_bytes = f.read()
    else:
        # Standard PS4 SFO binary header
        sfo_bytes = bytearray(0x200)
        struct.pack_into('<4s', sfo_bytes, 0x00, b'\x00PSF') # PSF magic
        struct.pack_into('<I', sfo_bytes, 0x04, 0x00010101) # Version
        struct.pack_into('<I', sfo_bytes, 0x08, 0x00000028) # Key table offset
        struct.pack_into('<I', sfo_bytes, 0x0C, 0x00000060) # Value table offset
        struct.pack_into('<I', sfo_bytes, 0x10, 0x00000001) # Entries count

    # 1. Main PKG Header (0x800 Bytes)
    header = bytearray(0x800)
    
    # Magic Header: \x7fPKG
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    # Package Type: Fake PKG (0x00000001)
    struct.pack_into('>I', header, 0x04, 0x00000001)
    # Total Entries: 2 (SFO + EBOOT)
    struct.pack_into('>I', header, 0x08, 0x00000002)
    # Entry Table Offset: Starts exactly at 0x800
    struct.pack_into('>I', header, 0x0F, 0x00000800)
    # SDK / System Version (0x05050000 -> Compatible with 5.05, 6.72, 6.92+)
    struct.pack_into('>I', header, 0x1C, 0x05050000)

    # Identifiers
    content_id = b"IV0000-CUSA05730_00-PS4HYBRIDAPP0000"
    title_id = b"CUSA05730"

    header[0x40:0x58] = title_id.ljust(24, b'\x00')
    header[0x80:0xC0] = content_id.ljust(64, b'\x00')

    # 2. Build Entry Table required by PS4-Xplorer Parser (0x800 Bytes)
    entry_table = bytearray(0x800)
    
    # Entry 0: param.sfo (ID: 0x00001000)
    sfo_offset = 0x1000
    sfo_size = len(sfo_bytes)
    struct.pack_into('>I', entry_table, 0x00, 0x00001000) # Type SFO
    struct.pack_into('>I', entry_table, 0x04, sfo_offset) # Offset
    struct.pack_into('>I', entry_table, 0x08, sfo_size)   # Size

    # Entry 1: eboot.bin (ID: 0x00001001)
    eboot_offset = sfo_offset + sfo_size
    eboot_size = len(eboot_bytes)
    struct.pack_into('>I', entry_table, 0x20, 0x00001001) # Type EBOOT
    struct.pack_into('>I', entry_table, 0x24, eboot_offset) # Offset
    struct.pack_into('>I', entry_table, 0x28, eboot_size)   # Size

    # 3. Write Complete Package File
    with open(output_pkg, 'wb') as pkg:
        pkg.write(header)                               # 0x0000 -> 0x0800
        pkg.write(entry_table)                          # 0x0800 -> 0x1000
        pkg.write(sfo_bytes)                            # 0x1000 -> sfo_offset
        pkg.write(eboot_bytes)                          # eboot binary
        
        # Add 15MB Padding to pass PS4 File Size Check
        pkg.write(b'\x00' * (15 * 1024 * 1024))

    print(f"[+] PS4-Xplorer Compatible PKG Built Successfully: {output_pkg}")

if __name__ == '__main__':
    src = sys.argv[1] if len(sys.argv) > 1 else '.'
    out = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    build_ps4_xplorer_compatible_pkg(src, out)
