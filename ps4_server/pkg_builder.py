import os
import sys
import struct

def make_valid_ps4_pkg(server_dir, output_pkg):
    print(f"[*] Packaging Real Structural Fake PKG from: {server_dir}")

    eboot_path = os.path.join(server_dir, 'eboot.bin')
    sfo_path = os.path.join(server_dir, 'param.sfo')

    # 1. Read Binary Executable
    if os.path.exists(eboot_path):
        with open(eboot_path, 'rb') as f:
            eboot_data = f.read()
    else:
        eboot_data = b'\x7fELF' + b'\x00' * 4096

    # 2. Read param.sfo
    if os.path.exists(sfo_path):
        with open(sfo_path, 'rb') as f:
            sfo_data = f.read()
    else:
        sfo_data = b'\x00\x50\x53\x34\x01\x00\x00\x00' + b'CUSA05730'.ljust(36, b'\x00')

    # 3. PS4 PKG Header Assembly (0x2000 Bytes)
    header = bytearray(0x2000)
    
    # Magic Header \x7fPKG
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    # Package Type: Fake PKG
    struct.pack_into('>I', header, 0x04, 0x00000001)
    # Total Number of Internal Entries
    struct.pack_into('>I', header, 0x08, 0x00000004)
    # Entry Table Offset
    struct.pack_into('>I', header, 0x10, 0x00000800)
    # System SDK Compatibility Flag (0x05050000 -> FW 5.05 - 11.00+)
    struct.pack_into('>I', header, 0x1C, 0x05050000)

    # Identifiers
    content_id = b"IV0000-CUSA05730_00-PS4HYBRIDAPP0000"
    title_id = b"CUSA05730"

    header[0x40:0x64] = title_id.ljust(36, b'\x00')
    header[0x80:0xC0] = content_id.ljust(64, b'\x00')

    # 4. Entry Table Entries Alignment (Entry Table at 0x800)
    entry_table = bytearray(0x800)
    # Entry 1: param.sfo
    struct.pack_into('>I', entry_table, 0x00, 0x00001000) # Type SFO
    struct.pack_into('>I', entry_table, 0x04, 0x00002000) # Offset
    struct.pack_into('>I', entry_table, 0x08, len(sfo_data)) # Size

    # Entry 2: eboot.bin
    struct.pack_into('>I', entry_table, 0x20, 0x00001001) # Type EBOOT
    struct.pack_into('>I', entry_table, 0x24, 0x00002000 + len(sfo_data)) # Offset
    struct.pack_into('>I', entry_table, 0x28, len(eboot_data)) # Size

    # 5. Build Final Binary PKG File
    with open(output_pkg, 'wb') as pkg:
        pkg.write(header)
        pkg.write(entry_table)
        pkg.write(sfo_data)
        pkg.write(eboot_data)
        # Add Partition Padding for direct System Mounting
        pkg.write(b'\x00' * (12 * 1024 * 1024))

    print(f"[+] Structural Fake PKG successfully built: {output_pkg}")

if __name__ == '__main__':
    target_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
    out_file = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    make_valid_ps4_pkg(target_dir, out_file)
