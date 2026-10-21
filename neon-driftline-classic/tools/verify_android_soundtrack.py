"""Ensure the final APK contains the exact Godot-imported soundtrack bytes."""
from pathlib import Path
import re
import sys
import zipfile

project = Path(__file__).resolve().parents[1]
settings = (project / "assets/audio/nineteen_steps.ogg.import").read_text()
resource_path = re.search(r'^path="res://([^"]+)"', settings, re.MULTILINE).group(1)
expected = (project / resource_path).read_bytes()
assert len(expected) > 1_000_000, "Imported soundtrack is empty or truncated"
with zipfile.ZipFile(sys.argv[1]) as apk:
    packaged = apk.read("assets/" + resource_path)
    assert packaged == expected, "APK soundtrack differs from imported song"
print(f"ANDROID SOUNDTRACK PACKAGE OK: {len(packaged)} imported bytes")
