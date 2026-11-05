#!/usr/bin/env python3
"""Assemble a multi-resolution macOS ICNS file from a standard iconset."""

import struct
import sys
from pathlib import Path


iconset = Path(sys.argv[1])
output = Path(sys.argv[2])
representations = [
    ("icp4", "icon_16x16.png"),
    ("icp5", "icon_16x16@2x.png"),
    ("icp6", "icon_32x32@2x.png"),
    ("ic07", "icon_128x128.png"),
    ("ic08", "icon_128x128@2x.png"),
    ("ic09", "icon_256x256@2x.png"),
    ("ic10", "icon_512x512@2x.png"),
]

chunks = bytearray()
for chunk_type, filename in representations:
    image = (iconset / filename).read_bytes()
    chunks.extend(chunk_type.encode("ascii"))
    chunks.extend(struct.pack(">I", len(image) + 8))
    chunks.extend(image)

output.parent.mkdir(parents=True, exist_ok=True)
output.write_bytes(b"icns" + struct.pack(">I", len(chunks) + 8) + chunks)
