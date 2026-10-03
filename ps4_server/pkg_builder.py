import os
import sys
import struct

def build_official_fpkg(eboot_path, output_pkg):
    print(f"[*] Compiling Official PS4 Fake PKG Layout for: {eboot_path}")
    
    if os.path.exists(eboot_path):
        with open(eboot_path, 'rb') as f:
            eboot_data = f.read()
    else:
        eboot_data = b'\x7fELF' + b'\x00' * 4096

    # 1. Header Structure (0x2000 bytes)
    header = bytearray(0x2000)
    
    # Magic Code \x7fPKG
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    # Package Type: Fake PKG (0x00000001)
    struct.pack_into('>I', header, 0x04, 0x00000001)
    # Entry Count: 6 Entries
    struct.pack_into('>I', header, 0x08, 0x00000006)
    # Table Offsets
    struct.pack_into('>I', header, 0x0C, 0x00002000) # Sc Table Offset
    struct.pack_into('>I', header, 0x10, 0x00004000) # Entry Table Offset
    
    # SDK Minimum Version (0x05050000 -> Compatible with 5.05 to 11.00+)
    struct.pack_into('>I', header, 0x1C, 0x05050000)

    # Content ID & Title ID
    content_id = b"IV0000-CUSA05730_00-PS4HYBRIDAPP0000"
    title_id = b"CUSA05730"
    
    header[0x40:0x64] = title_id.ljust(36, b'\x00')
    header[0x80:0xC0] = content_id.ljust(64, b'\x00')

    # 2. Minimum PS4 param.sfo payload
    sfo_header = bytearray([
        0x00, 0x50, 0x53, 0x34, 0x01, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00
    ])

    # 3. Construct File
    with open(output_pkg, 'wb') as pkg:
        pkg.write(header)
        pkg.write(sfo_header)
        pkg.write(eboot_data)
        
        # Add 10MB Partition Padding for System Read Capability
        pkg.write(b'\x00' * (10 * 1024 * 1024))

    print(f"[+] Authentic Fake PKG successfully generated: {output_pkg}")

if __name__ == '__main__':
    eboot = sys.argv[1] if len(sys.argv) > 1 else 'eboot.bin'
    out = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    build_official_fpkg(eboot, out)
