#!/usr/bin/env python3
"""Closed CFF1 semantic projection for the pinned fontTools reader."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys


def _number(value: float | int) -> int | float:
    as_float = float(value)
    if as_float.is_integer():
        return int(as_float)
    return as_float


def _command(name: str, points: tuple[tuple[float, float], ...]) -> dict[str, object]:
    op_by_name = {
        "moveTo": "MoveTo",
        "lineTo": "LineTo",
        "curveTo": "CubicTo",
        "closePath": "Close",
        "endPath": "Close",
    }
    if name not in op_by_name:
        raise ValueError(f"unsupported pen operation: {name}")
    flattened: list[int | float] = []
    for point in points:
        flattened.extend((_number(point[0]), _number(point[1])))
    return {"op": op_by_name[name], "points": flattened}


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--site-root", required=True)
    parser.add_argument("--font", required=True)
    parser.add_argument("--scalar", default="U+0041")
    args = parser.parse_args()

    site_root = pathlib.Path(args.site_root).resolve(strict=True)
    font_path = pathlib.Path(args.font).resolve(strict=True)
    sys.path.insert(0, str(site_root))

    from fontTools import __version__ as fonttools_version
    from fontTools.pens.boundsPen import BoundsPen
    from fontTools.pens.recordingPen import RecordingPen
    from fontTools.ttLib import TTFont

    if fonttools_version != "4.63.0":
        raise RuntimeError(f"fontTools version drift: {fonttools_version}")

    scalar = int(args.scalar[2:], 16)
    font = TTFont(font_path, checkChecksums=2, lazy=False, recalcBBoxes=False)
    if "CFF " not in font or "CFF2" in font or "glyf" in font:
        raise RuntimeError("reader accepts only static CFF1 outlines")

    cmap = font.getBestCmap()
    if scalar not in cmap:
        raise RuntimeError(f"scalar is unmapped: {args.scalar}")
    glyph_name = cmap[scalar]
    glyph_order = font.getGlyphOrder()
    gid = glyph_order.index(glyph_name)
    glyph_set = font.getGlyphSet()
    glyph = glyph_set[glyph_name]

    recording = RecordingPen()
    glyph.draw(recording)
    commands = [_command(name, points) for name, points in recording.value]

    bounds_pen = BoundsPen(glyph_set)
    glyph.draw(bounds_pen)
    if bounds_pen.bounds is None:
        bounds: list[int | float] = []
    else:
        bounds = [_number(value) for value in bounds_pen.bounds]

    top_dict = font["CFF "].cff.topDictIndex[0]
    ros_value = getattr(top_dict, "ROS", None)
    ros = list(ros_value) if ros_value else None
    keying = "cid" if ros else "name"
    if ros:
        fd_array = list(top_dict.FDArray)
        fd_select = list(top_dict.FDSelect.gidArray)
        fd_count: int | None = len(fd_array)
        used_fds = sorted(set(fd_select))
        selected_fd: int | None = int(fd_select[gid])
        fd_select_format: int | None = int(top_dict.FDSelect.format)
    else:
        fd_count = None
        used_fds = []
        selected_fd = None
        fd_select_format = None
    source = font_path.read_bytes()
    result = {
        "schema": "cff-semantic-reader/1.0.0",
        "source_sha256": hashlib.sha256(source).hexdigest(),
        "face_index": 0,
        "scalar": args.scalar,
        "glyph_name": glyph_name,
        "gid": gid,
        "advance": _number(glyph.width),
        "lsb": _number(glyph.lsb),
        "bounds": bounds,
        "commands": commands,
        "cff_profile": "CFF1",
        "keying": keying,
        "ros": ros,
        "fd_count": fd_count,
        "used_fds": used_fds,
        "selected_fd": selected_fd,
        "fd_select_format": fd_select_format,
        "reader": "fonttools",
        "reader_version": fonttools_version,
    }
    json.dump(result, sys.stdout, ensure_ascii=True, separators=(",", ":"))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
