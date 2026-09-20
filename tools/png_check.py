#!/usr/bin/env python3
"""Checks KODO's PNG encoder with an inflater it did not write.

`png.dart` contains a hand-rolled LZ77 and RFC 1951's fixed Huffman tables, written out
because a pure-Dart package with no dependencies has no compressor to call. The only
honest way to believe a compressor is to hand its output to somebody else's decompressor,
so that is what this does: Python's zlib, which shares no code and no author with ours.

    dart run tool/emit_pngs.dart build/png-check
    python3 tools/png_check.py build/png-check

Every file must inflate, every chunk CRC must match, and the inflated scanlines must be
exactly the size the header promised.
"""
import glob
import os
import struct
import sys
import zlib


def check(path: str) -> tuple[bool, str]:
    data = open(path, "rb").read()
    if data[:8] != b"\x89PNG\r\n\x1a\x0a":
        return False, "not a PNG"

    offset, idat, width, height, depth, colour = 8, b"", None, None, None, None
    while offset < len(data):
        (length,) = struct.unpack(">I", data[offset : offset + 4])
        kind = data[offset + 4 : offset + 8]
        body = data[offset + 8 : offset + 8 + length]
        (stored_crc,) = struct.unpack(">I", data[offset + 8 + length : offset + 12 + length])
        if stored_crc != zlib.crc32(kind + body) & 0xFFFFFFFF:
            return False, f"{kind.decode()} chunk CRC is wrong"
        if kind == b"IHDR":
            width, height, depth, colour = struct.unpack(">IIBB", body[:10])
        elif kind == b"IDAT":
            idat += body
        offset += 12 + length

    if width is None:
        return False, "no IHDR"
    try:
        raw = zlib.decompress(idat)
    except zlib.error as error:
        return False, f"will not inflate: {error}"

    stride = width + 1 if colour == 3 else width * 3 + 1
    if len(raw) != height * stride:
        return False, f"inflated to {len(raw)}, header promised {height * stride}"
    for y in range(height):
        if raw[y * stride] != 0:
            return False, f"row {y} uses filter {raw[y * stride]}, only 0 is written"

    ratio = os.path.getsize(path) / len(raw)
    return True, (
        f"{width}x{height} type {colour}, {os.path.getsize(path)} bytes "
        f"for {len(raw)} raw ({ratio * 100:.2f}%)"
    )


def main() -> int:
    where = sys.argv[1] if len(sys.argv) > 1 else "build/png-check"
    files = sorted(glob.glob(os.path.join(where, "*.png")))
    if not files:
        print(f"no PNGs in {where} — run the emitter first", file=sys.stderr)
        return 1

    failed = 0
    for path in files:
        ok, detail = check(path)
        print(f"  {'ok  ' if ok else 'FAIL'}  {os.path.basename(path):16} {detail}")
        failed += 0 if ok else 1

    print(f"\n{len(files) - failed} of {len(files)} PNGs inflate under an "
          f"independent decoder")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
