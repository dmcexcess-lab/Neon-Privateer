"""Mirror authoritative native hacking source into the standalone Godot project."""
from pathlib import Path
import shutil

root = Path(__file__).resolve().parents[1]
for source in sorted((root / 'hacking').glob('*')):
    if source.suffix in {'.gd', '.uid'}:
        shutil.copy2(source, root / 'neon-firewall' / 'scripts' / source.name)
print('Neon Firewall standalone source synchronized from hacking/')
