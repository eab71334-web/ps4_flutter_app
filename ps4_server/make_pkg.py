import os
import sys
import subprocess

def create_ps4_fake_pkg():
    print("[*] Generating PS4 Official Fake PKG Structure for CUSA05730...")
    
    # 1. Ensure directories exist
    pkg_dir = "pkg_build"
    sce_sys_dir = os.path.join(pkg_dir, "sce_sys")
    os.makedirs(sce_sys_dir, exist_ok=True)

    # 2. GP4 Project File for Orbis Publishing Tool
    gp4_content = """<?xml version="1.0" encoding="utf-8" standalone="yes"?>
<package volume="0" volume_ts="1">
  <fmt_config type="ps4_app"/>
  <volume>
    <volume_id>PS4_HYBRID_HOST</volume_id>
    <volume_number>1</volume_number>
    <volume_count>1</volume_count>
    <package_id>CUSA05730</package_id>
  </volume>
  <files img_type="activation">
    <file target_path="sce_sys/param.sfo" source_path="sce_sys/param.sfo"/>
    <file target_path="eboot.bin" source_path="eboot.bin"/>
  </files>
</package>"""

    with open("project.gp4", "w") as f:
        f.write(gp4_content)

    # 3. Create param.sfo Header (CUSA05730 - PS4 Hybrid Host)
    sfo_header = bytearray([
        0x00, 0x50, 0x53, 0x34, 0x01, 0x01, 0x00, 0x00,
        0x02, 0x00, 0x00, 0x00, 0x48, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00
    ])
    
    with open(os.path.join(sce_sys_dir, "param.sfo"), "wb") as f:
        f.write(sfo_header)

    print("[+] PS4 Metadata & GP4 files generated successfully.")

if __name__ == '__main__':
    create_ps4_fake_pkg()
