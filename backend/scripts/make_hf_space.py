"""
Make the folder to upload to a Hugging Face Space (the free, no-card way to put the backend online).

Run from the repo root or the backend/ folder:

    python backend/scripts/make_hf_space.py

It makes the folder  hf-space/  (next to backend/, ignored by Git) with ONLY what the server needs:

    hf-space/
        Dockerfile            how Hugging Face starts the backend (deploy/huggingface/Dockerfile)
        README.md             the Space's settings card (deploy/huggingface/README.md)
        requirements.txt      the Python libraries
        backend/app/          the server code
        backend/data/         the problem bank

No tests, no SQL, and NEVER a .env file or any key: the secrets are pasted in the Space's settings.
Then follow docs/deploy_huggingface.md to upload it.
"""

import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "hf-space"
MARKER = ".made-by-make_hf_space"  # so the script only ever deletes a folder it made itself

SKIP_DIRS = {"__pycache__", ".pytest_cache"}
SKIP_SUFFIXES = {".pyc", ".pyo"}


def _is_secret(path):
    """True for any file that could hold a key (.env, .env.local, ...)."""
    return path.name.startswith(".env")


def _copy_tree(source, target):
    for path in sorted(source.rglob("*")):
        rel = path.relative_to(source)
        if any(part in SKIP_DIRS for part in rel.parts) or path.suffix in SKIP_SUFFIXES or _is_secret(path):
            continue
        if path.is_file():
            dest = target / rel
            dest.parent.mkdir(parents=True, exist_ok=True)
            shutil.copy2(path, dest)


def make(out=OUT):
    """Build the upload folder. Returns the list of files in it (paths relative to the folder)."""
    out = Path(out)
    if out.exists():
        if not (out / MARKER).exists():
            sys.exit(f"{out} exists but was not made by this script; not touching it.")
        shutil.rmtree(out)
    out.mkdir(parents=True)
    (out / MARKER).write_text("This folder is rebuilt by backend/scripts/make_hf_space.py\n", encoding="utf-8")

    shutil.copy2(ROOT / "deploy" / "huggingface" / "Dockerfile", out / "Dockerfile")
    shutil.copy2(ROOT / "deploy" / "huggingface" / "README.md", out / "README.md")
    shutil.copy2(ROOT / "requirements.txt", out / "requirements.txt")
    _copy_tree(ROOT / "backend" / "app", out / "backend" / "app")
    _copy_tree(ROOT / "backend" / "data", out / "backend" / "data")

    # The marker stays (a harmless one-line note), so the next run may rebuild this folder.
    return sorted(str(p.relative_to(out)).replace("\\", "/") for p in out.rglob("*")
                  if p.is_file() and p.name != MARKER)


def main():
    files = make()
    print(f"Made {OUT} with {len(files)} files:")
    for name in files:
        print("  ", name)
    print("\nNo .env and no keys inside. Next: docs/deploy_huggingface.md, Step 3 (upload).")


if __name__ == "__main__":
    main()
