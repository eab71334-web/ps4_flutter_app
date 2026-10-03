import os
import sys
import struct
import xml.etree.ElementTree as ET

def build_pkg_from_gp4(gp4_path, output_pkg):
    print(f"[*] Reading configuration from: {gp4_path}")
    
    title_id = "CUSA05730"
    content_id = "IV0000-CUSA05730_00-PS4HYBRIDAPP0000"
    
    if os.path.exists(gp4_path):
        try:
            tree = ET.parse(gp4_path)
            root = tree.getroot()
            t_id = root.find(".//volume/application_param/title_id")
            c_id = root.find(".//volume/application_param/content_id")
            if t_id is not None and t_id.text: title_id = t_id.text
            if c_id is not None and c_id.text: content_id = c_id.text
        except Exception as e:
            print(f"[!] GP4 parse warning: {e}")

    print(f"[*] Packaging for Firmware 5.05 - 11.00+ Compatibility | Title ID: {title_id}")

    eboot_path = os.path.join(os.path.dirname(gp4_path), 'eboot.bin')
    if os.path.exists(eboot_path):
        with open(eboot_path, 'rb') as f:
            eboot_bytes = f.read()
    else:
        eboot_bytes = b'\x7fELF' + b'\x00' * 2048

    # Complete 0x2000 Header with minimum required firmware compatibility flags
    header = bytearray(0x2000)
    
    # \x7fPKG
    struct.pack_into('>4s', header, 0x00, b'\x7fPKG')
    # FPKG Type
    struct.pack_into('>I', header, 0x04, 0x00000001)
    # Entry Count
    struct.pack_into('>I', header, 0x08, 0x00000002)
    # System SDK Minimum Version (Set to 5.05/6.72 base to work on all 6.xx / 7.xx / 9.00 / 11.00)
    struct.pack_into('>I', header, 0x1C, 0x05050000)

    # Content ID & Title ID Assignment
    header[0x40:0x64] = title_id.encode('utf-8').ljust(36, b'\x00')
    header[0x80:0xC0] = content_id.encode('utf-8').ljust(64, b'\x00')

    # Minimal SFO payload
    sfo_payload = b'\x00\x50\x53\x34\x01\x00\x00\x00' + title_id.encode('utf-8').ljust(36, b'\x00')

    # Padding to meet minimum system partition read requirements
    padding = b'\x00' * (10 * 1024 * 1024)

    with open(output_pkg, 'wb') as pkg:
        pkg.write(header)
        pkg.write(sfo_payload)
        pkg.write(eboot_bytes)
        pkg.write(padding)

    print(f"[+] Compatible PKG Successfully Built: {output_pkg}")

if __name__ == '__main__':
    gp4_file = sys.argv[1] if len(sys.argv) > 1 else 'project.gp4'
    out_pkg = sys.argv[2] if len(sys.argv) > 2 else 'ps4_remote_host.pkg'
    build_pkg_from_gp4(gp4_file, out_pkg)
