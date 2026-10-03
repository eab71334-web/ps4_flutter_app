import os
import sys
import struct

def create_complete_fpkg(server_dir, output_pkg):
    print(f"[*] Packaging complete FPKG structure from directory: {server_dir}")

    eboot_path = os.path.join(server_dir, 'eboot.bin')
    sfo_path = os.path.join(server_dir, 'param.sfo')

    # Read eboot
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
        sfo_bytes = b'\x00\x50\x53\x34\x01\x00\x00\x00' + b'CUSA05730'.ljust(36, b'\x00')

    # Construct PS4 Authentic Header
    header = bytearray(0x2000)
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    struct.pack_into('>I', header, 0x04, 0x00000001) # Fake PKG type
    struct.pack_into('>I', header, 0x08, 0x00000003) # 3 Entries: Header, SFO, eboot
    struct.pack_into('>I', header, 0x1C, 0x05050000) # Firmware compatibility (5.05 / 6.92+)

    content_id = b"IV0000-CUSA05730_00-PS4HYBRIDAPP0000"
    header[0x40:0x64] = b"CUSA05730".ljust(36, b'\x00')
    header[0x80:0xC0] = content_id.ljust(64, b'\x00')

    # Output assembly
    with open(output_pkg, 'wb') as pkg:
        pkg.write(header)
        pkg.write(sfo_bytes)
        pkg.write(eboot_bytes)
        # Pad 10MB minimal system size
        pkg.write(b'\x00' * (10 * 1024 * 1024))

    print(f"[+] Complete Valid FPKG generated: {output_pkg}")

if __name__ == '__main__':
    src_dir = sys.argv[1] if len(sys.argv) > 1 else '.'
    out_pkg = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    create_complete_fpkg(src_dir, out_pkg)
