#!/usr/bin/env python3
"""Check a built patch against the layout. Given Waldorf's update file as
well, apply the patch with the browser patcher under Node."""
import json
from pathlib import Path
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]


def apply(update: Path, patch: Path) -> dict:
    """The SHA-256 of the OS and update file web/patcher.mjs makes."""
    result = subprocess.run(["node", str(ROOT / "tools/apply_patch.mjs"), str(update), str(patch)],
                            capture_output=True, text=True)
    if result.returncode:
        raise ValueError(result.stderr.strip() or "the browser patcher failed")
    return json.loads(result.stdout)


def main():
    if len(sys.argv) not in (2, 3):
        sys.exit(__doc__)
    patch_path = Path(sys.argv[1])
    patch, layout = json.loads(patch_path.read_text()), json.loads((ROOT / "src/patch_layout.json").read_text())
    if [h["address"] for h in patch["hunks"]] != [h["address"] for h in layout["hunks"]]:
        raise ValueError("the patch's hunks differ from the layout")
    print(f"{patch_path}: {len(patch['hunks'])} hunks, {len(patch['extension']['data']) // 2} extension bytes")
    if len(sys.argv) == 2:
        print("Set XT_STOCK_UPDATE to Waldorf's OS v2.33 update to apply the patch as well.")
        return
    made = apply(Path(sys.argv[2]), patch_path)
    print(f"applied: OS SHA-256 {made['overlay_sha256']}")


if __name__ == "__main__":
    try:
        main()
    except (OSError, ValueError, KeyError) as error:
        sys.exit(f"check: {error}")
