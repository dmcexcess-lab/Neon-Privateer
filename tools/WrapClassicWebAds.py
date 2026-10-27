"""Compatibility entry point for the Classic game page build."""
from pathlib import Path
import sys
from WrapPrivateerBeta import wrap

if __name__ == '__main__':
    wrap(Path(sys.argv[1]), sys.argv[2] if len(sys.argv) > 2 else 'local', 'classic')
