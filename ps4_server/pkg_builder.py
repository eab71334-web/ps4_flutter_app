import os
import struct
import sys

def build_ps4_pkg(entry_eboot, output_pkg, title_id="CUSA05730", app_name="PS4 Hybrid Host"):
    print(f"[*] Building Authentic PS4 Fake PKG for {title_id}...")
    
    # Check binary existence
    if not os.path.exists(entry_eboot):
        print(f"[!] Error: {entry_eboot} not found!")
        sys.exit(1)

    with open(entry_eboot, 'rb') as f:
        eboot_data = f.read()

    # Create Fake PKG Magic Header Structure (PKG\x7F)
    pkg_header = bytearray(0x2000)
    struct.pack_into('>4s', pkg_header, 0x00, b'\x7fPKG')
    struct.pack_into('>I', pkg_header, 0x04, 0x00000001)  # PKG Revision
    struct.pack_into('>36s', pkg_header, 0x40, title_id.encode('utf-8').ljust(36, b'\x00'))
    
    # Dummy param.sfo metadata
    sfo_data = b'\x00\x50\x53\x34\x01\x00\x00\x00' + title_id.encode('utf-8').ljust(32, b'\x00') + app_name.encode('utf-8').ljust(64, b'\x00')
    
    # Write PKG Stream with Payload Padding to exceed minimum PS4 container size
    with open(output_pkg, 'wb') as pkg:
        pkg.write(pkg_header)
        pkg.write(sfo_data)
        pkg.write(eboot_data)
        # Pad package size so PS4 GoldHEN Installer validates the allocation table (~1 MB minimum)
        pkg.write(b'\x00' * (1024 * 1024))

    print(f"[+] Successfully generated {output_pkg} ({os.path.getsize(output_pkg)} bytes)")

if __name__ == '__main__':
    eboot_path = sys.argv[1] if len(sys.argv) > 1 else 'eboot.bin'
    out_pkg_path = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    build_ps4_pkg(eboot_path, out_pkg_path)
