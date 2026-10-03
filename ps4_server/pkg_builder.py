import os
import sys
import struct

def build_valid_dummy_pkg(eboot_path, output_pkg):
    print(f"[*] Creating Valid Minimal PS4 PKG Structure for {eboot_path}...")
    
    # Read eboot binary
    if os.path.exists(eboot_path):
        with open(eboot_path, 'rb') as f:
            eboot_data = f.read()
    else:
        eboot_data = b'\x7fELF' + b'\x00' * 1024

    # Magic Header \x7fPKG
    header = bytearray(0x800)
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    struct.pack_into('>I', header, 0x04, 0x00000001) # PKG Type: Fake
    struct.pack_into('>I', header, 0x08, 0x00000000) # Entry count
    
    # Title ID: CUSA05730
    title_id = "CUSA05730".encode('utf-8').ljust(36, b'\x00')
    header[0x40:0x64] = title_id

    # Construct file
    with open(output_pkg, 'wb') as f:
        f.write(header)
        f.write(eboot_data)
        # Adding zero padding (1MB total size for super fast testing)
        f.write(b'\x00' * (1024 * 1024))

    print(f"[+] Output PKG generated: {output_pkg}")

if __name__ == '__main__':
    eboot = sys.argv[1] if len(sys.argv) > 1 else 'eboot.bin'
    out = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    build_valid_dummy_pkg(eboot, out)
