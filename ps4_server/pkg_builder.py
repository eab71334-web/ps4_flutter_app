import os
import struct
import sys

def build_sparse_ps4_pkg(eboot_path, output_pkg, title_id="CUSA05730", app_name="PS4 Hybrid Host Engine"):
    print(f"[*] Packaging {eboot_path} into Compressible PS4 Fake PKG Structure...")
    
    if not os.path.exists(eboot_path):
        print(f"[!] Error: {eboot_path} not found.")
        sys.exit(1)

    with open(eboot_path, 'rb') as f:
        eboot_bytes = f.read()

    # Header Structure (\x7fPKG)
    header = bytearray(0x2000)
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    struct.pack_into('>I', header, 0x04, 0x00000001)
    struct.pack_into('>36s', header, 0x40, title_id.encode('utf-8').ljust(36, b'\x00'))

    # Metadata Header
    sfo_data = b'\x00\x50\x53\x34\x01\x00\x00\x00' + title_id.encode('utf-8').ljust(32, b'\x00') + app_name.encode('utf-8').ljust(64, b'\x00')

    # Highly-compressible Zero Padding (26 MB) so zip size is ultra-small (<50 KB)
    zero_padding = b'\x00' * (26 * 1024 * 1024)

    with open(output_pkg, 'wb') as pkg:
        pkg.write(header)
        pkg.write(sfo_data)
        pkg.write(eboot_bytes)
        pkg.write(zero_padding)

    print(f"[+] PKG Generated: {output_pkg} | Raw Size: {os.path.getsize(output_pkg) / (1024*1024):.2f} MB")

if __name__ == '__main__':
    eboot = sys.argv[1] if len(sys.argv) > 1 else 'eboot.bin'
    out = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    build_sparse_ps4_pkg(eboot, out)
