import os
import struct
import sys

def create_fake_pkg(eboot_path, output_pkg, title_id="CUSA05730"):
    print(f"[*] Packaging {eboot_path} into valid PS4 Fake PKG ({title_id})...")
    
    if not os.path.exists(eboot_path):
        print(f"[!] Error: {eboot_path} does not exist.")
        sys.exit(1)

    with open(eboot_path, 'rb') as f:
        eboot_bytes = f.read()

    # PS4 PKG Header Structure (\x7fPKG)
    header = bytearray(0x2000)
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    struct.pack_into('>I', header, 0x04, 0x00000001)
    struct.pack_into('>36s', header, 0x40, title_id.encode('utf-8').ljust(36, b'\x00'))

    # Metadata & Entry Table Setup
    sfo_data = b'\x00\x50\x53\x34\x01\x00\x00\x00' + title_id.encode('utf-8').ljust(32, b'\x00')

    with open(output_pkg, 'wb') as pkg:
        pkg.write(header)
        pkg.write(sfo_data)
        pkg.write(eboot_bytes)
        # Minimum Container Padding (~2MB) so PS4 GoldHEN Package Installer reads it correctly
        pkg.write(b'\x00' * (2 * 1024 * 1024))

    print(f"[+] PKG generated successfully: {output_pkg} ({os.path.getsize(output_pkg)} bytes)")

if __name__ == '__main__':
    eboot = sys.argv[1] if len(sys.argv) > 1 else 'eboot.bin'
    out = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    create_fake_pkg(eboot, out)
