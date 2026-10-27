#!/usr/bin/env python3
"""Assemble the hooks and the extension and package them as a patch.

No Waldorf firmware is an input: src/hooks.asm assembles against the stock
addresses in src/stock_abi.inc, and the patch keeps only the ranges
src/patch_layout.json lists plus the extension region. The browser patcher,
web/patcher.mjs, applies it to the user's own copy of Waldorf's update."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(Path(__file__).resolve().parent))
import edition_version

FILLS = (0x00, 0xFF)  # assembled twice: a byte that differs between fills was not written


def number(value) -> int:
    """An address or size from the layout: a hex string or an integer."""
    return value if type(value) is int else int(value, 16)


def assemble(build: Path, asl: str, p2bin: str, layout: dict, include: tuple = ()) -> list[bytes]:
    """The image hooks.asm writes, once per fill byte."""
    build.mkdir(parents=True, exist_ok=True)
    edition_version.write(ROOT / "VERSION", build / "edition.inc")
    obj = build / "hooks.p"
    paths = [arg for directory in (ROOT / "src", build, *include) for arg in ("-i", str(directory))]
    subprocess.run([asl, "-q", "-L", *paths, "-o", str(obj),
                    "-olist", str(build / "hooks.lst"), str(ROOT / "src/hooks.asm")], check=True)
    base, end = number(layout["firmware"]["base_address"]), number(layout["extension"]["end"])
    images = []
    for fill in FILLS:
        out = build / f"hooks-{fill:02x}.bin"
        subprocess.run([p2bin, "-q", "-l", str(fill), "-r", f"${base:x}-${end:x}", str(obj), str(out)], check=True)
        images.append(out.read_bytes())
    return images


def make_patch(build: Path, asl: str, p2bin: str, layout_path: Path, include: tuple = ()) -> dict:
    layout = json.loads(layout_path.read_text())
    base = number(layout["firmware"]["base_address"])
    low, high = assemble(build, asl, p2bin, layout, include)
    written = {offset for offset, (a, b) in enumerate(zip(low, high)) if a == b}
    allowed = set()
    hunks = []
    for hunk in layout["hunks"]:
        start, size = number(hunk["address"]) - base, number(hunk["bytes"])
        allowed.update(range(start, start + size))
        if not set(range(start, start + size)) <= written:
            raise ValueError(f"hooks.asm does not write all of {hunk['site']}")
        hunks.append({"address": hunk["address"], "data": low[start:start + size].hex()})
    region_start = number(layout["extension"]["start"]) - base
    in_region = sorted(offset for offset in written if offset >= region_start)
    if not in_region:
        raise ValueError("no extension was assembled")
    region_end = in_region[-1] + 1
    allowed.update(range(region_start, region_end))
    stray = sorted(written - allowed)
    if stray:
        raise ValueError(f"hooks.asm writes outside the layout at 0x{base + stray[0]:06x}")
    patch = {"format": 1, "base_sha256": layout["firmware"]["overlay_sha256"], "hunks": hunks,
             "extension": {"address": layout["extension"]["start"], "data": low[region_start:region_end].hex()}}
    patch["_summary"] = (f"{len(hunks)} hunks, extension {region_end - region_start} of "
                         f"{number(layout['extension']['end']) - number(layout['extension']['start']) + 1} bytes")
    return patch


def write_patch(patch: dict, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    output.write_text(json.dumps({k: v for k, v in patch.items() if not k.startswith("_")}, indent=1) + "\n")


def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("output", type=Path)
    parser.add_argument("--asl", default="asl")
    parser.add_argument("--p2bin", default="p2bin")
    parser.add_argument("--layout", type=Path, default=ROOT / "src/patch_layout.json")
    parser.add_argument("--build", type=Path, default=ROOT / "build")
    args = parser.parse_args()
    patch = make_patch(args.build, args.asl, args.p2bin, args.layout)
    write_patch(patch, args.output)
    print(f"{args.output}: {patch['_summary']}")


if __name__ == "__main__":
    main()
