#!/usr/bin/env python3
"""Package the patch and the self-contained browser patcher.

The release's patch names the files that applying it must give, so this
needs Waldorf's update file once; nothing of it goes into the package."""
import hashlib
import json
from pathlib import Path
import re
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT / "tools"))
from check_patch import apply

PATCH_NAME, PAGE_NAME = "microwave-xt.xtpatch", "microwave-xt-patcher.html"
SOUNDS_NAME = "tallent-edition-sounds.syx"
SCRIPT_MARKER = "<!-- PATCHER_SCRIPT -->"
VERSION_MARKER = "{{VERSION}}"


def main():
    if len(sys.argv) != 2:
        sys.exit("usage: package_release.py WALDORF_V233_UPDATE")
    layout = json.loads((ROOT / "src/patch_layout.json").read_text())
    patch = json.loads((ROOT / "build" / PATCH_NAME).read_text())
    patch.pop("result", None)
    patch["result"] = apply(Path(sys.argv[1]), ROOT / "build" / PATCH_NAME)
    encoded = (json.dumps(patch, indent=1) + "\n").encode()
    dist = ROOT / "dist"
    dist.mkdir(exist_ok=True)
    (dist / PATCH_NAME).write_bytes(encoded)
    # The result is checked as the page checks it.
    if apply(Path(sys.argv[1]), dist / PATCH_NAME) != patch["result"]:
        raise ValueError("the packaged patch makes different files")

    web = ROOT / "web"
    payload = json.dumps({"patch": patch, "layout": layout}, separators=(",", ":")).replace("<", "\\u003c")
    core = re.sub(r"^export ", "", (web / "patcher.mjs").read_text(), flags=re.M)
    script = ('<script id="firmware-data" type="application/json">' + payload + "</script>\n"
              '<script type="module">\n' + core + "\n" + (web / "app.mjs").read_text() + "\n</script>")
    template = (web / "patcher.template.html").read_text()
    if template.count(SCRIPT_MARKER) != 1:
        raise ValueError("browser template must contain exactly one script marker")
    if VERSION_MARKER not in template:
        raise ValueError("browser template must show the version")
    version = (ROOT / "VERSION").read_text().strip()
    html = template.replace(VERSION_MARKER, version).replace(SCRIPT_MARKER, script)
    (ROOT / "patcher.html").write_text(html)
    (dist / PAGE_NAME).write_text(html)
    sounds = (ROOT / SOUNDS_NAME).read_bytes()
    (dist / SOUNDS_NAME).write_bytes(sounds)
    manifest = {
        "format": 1,
        "firmware": layout["firmware"]["version"],
        "version": version,
        "overlay_sha256": patch["result"]["overlay_sha256"],
        "files": {PATCH_NAME: hashlib.sha256(encoded).hexdigest(), PAGE_NAME: hashlib.sha256(html.encode()).hexdigest(),
                  SOUNDS_NAME: hashlib.sha256(sounds).hexdigest()},
    }
    (dist / "manifest.json").write_text(json.dumps(manifest, indent=2) + "\n")
    print(f"Packaged version {version}, OS SHA-256 {manifest['overlay_sha256']}, in {dist}; no Waldorf software included")


if __name__ == "__main__":
    main()
