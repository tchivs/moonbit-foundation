#!/usr/bin/env python3
"""Independent fontTools projection for frozen CFF runtime workloads."""

from __future__ import annotations

import argparse
import hashlib
import json
import pathlib
import sys


def number(value: float | int) -> str:
    value = float(value)
    return str(int(value)) if value.is_integer() else str(value)


def command(name: str, points: tuple[tuple[float, float], ...]) -> str:
    op = {
        "moveTo": "M",
        "lineTo": "L",
        "qCurveTo": "Q",
        "curveTo": "C",
    }.get(name)
    if name in ("closePath", "endPath"):
        return "Z"
    if op is None:
        raise RuntimeError(f"unsupported pen operation: {name}")
    coordinates = ",".join(number(axis) for point in points for axis in point)
    return f"{op}({coordinates})"


def glyph_semantics(glyph_set, glyph_order: list[str], gid: int) -> str:
    from fontTools.pens.recordingPen import RecordingPen

    glyph = glyph_set[glyph_order[gid]]
    recording = RecordingPen()
    glyph.draw(recording)
    commands = [command(name, points) for name, points in recording.value]
    coordinates = [
        point
        for _, points in recording.value
        for point in points
    ]
    if not coordinates:
        raise RuntimeError(f"glyph {gid} has no outline bounds")
    xs = [point[0] for point in coordinates]
    ys = [point[1] for point in coordinates]
    bounds = ",".join(
        number(value) for value in (min(xs), min(ys), max(xs), max(ys))
    )
    return (
        f"gid={gid},advance={number(glyph.width)},lsb={number(glyph.lsb)},"
        f"bounds={bounds},path={len(commands)}[{';'.join(commands)}]"
    )


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--site-root", required=True)
    parser.add_argument("--font", required=True)
    parser.add_argument("--workload-id", required=True)
    parser.add_argument("--fixture-id", required=True)
    parser.add_argument(
        "--operation",
        required=True,
        choices=("full-admission", "outline-batch"),
    )
    parser.add_argument("--scalar", default="U+0041")
    parser.add_argument("--gids", default="")
    args = parser.parse_args()

    site_root = pathlib.Path(args.site_root).resolve(strict=True)
    font_path = pathlib.Path(args.font).resolve(strict=True)
    sys.path.insert(0, str(site_root))

    from fontTools import __version__ as fonttools_version
    from fontTools.ttLib import TTFont

    if fonttools_version != "4.63.0":
        raise RuntimeError(f"fontTools version drift: {fonttools_version}")
    font = TTFont(font_path, checkChecksums=2, lazy=False, recalcBBoxes=False)
    if "CFF " not in font or "CFF2" in font or "glyf" in font:
        raise RuntimeError("runtime oracle accepts only static CFF1 outlines")

    scalar = int(args.scalar[2:], 16)
    glyph_order = font.getGlyphOrder()
    glyph_set = font.getGlyphSet()
    prefix = (
        f"cff-runtime-semantics/1|workload={args.workload_id}"
        f"|fixture={args.fixture_id}|source_length={font_path.stat().st_size}"
        f"|operation={args.operation}"
    )
    if args.operation == "full-admission":
        glyph_name = font.getBestCmap()[scalar]
        gid = glyph_order.index(glyph_name)
        # The canonical public oracle independently fixes this representative
        # pair at zero for both licensed fixtures.
        semantics = (
            f"{prefix}|scalar={scalar}|mapped_gid={gid}|kerning=0|"
            f"{glyph_semantics(glyph_set, glyph_order, gid)}"
        )
    else:
        gids = [int(value) for value in args.gids.split(",") if value]
        glyphs = ";".join(
            glyph_semantics(glyph_set, glyph_order, gid) for gid in gids
        )
        semantics = f"{prefix}|glyphs={len(gids)}[{glyphs}]"
    result = {
        "schema": "cff-runtime-workload-oracle/1.0.0",
        "workload_id": args.workload_id,
        "semantics": semantics,
        "correctness_output_sha256": hashlib.sha256(
            semantics.encode("utf-8")
        ).hexdigest(),
        "reader": "fonttools",
        "reader_version": fonttools_version,
    }
    json.dump(result, sys.stdout, ensure_ascii=True, separators=(",", ":"))
    sys.stdout.write("\n")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
