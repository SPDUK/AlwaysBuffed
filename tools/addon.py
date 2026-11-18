"""Package a standalone addon or install the exact packaged files into WoW."""

import argparse
import os
import re
import shutil
import tempfile
from pathlib import Path
from zipfile import ZIP_DEFLATED, ZipFile, ZipInfo


ROOT = Path(__file__).resolve().parents[1]
DEFAULT_GAME = Path(os.environ.get("ProgramFiles(x86)", r"C:\Program Files (x86)")) / "World of Warcraft" / "_forever_"


def release_files(name):
    if not re.fullmatch(r"[A-Za-z0-9_-]+", name):
        raise ValueError("Use an addon folder name.")
    source = ROOT / name
    toc = source / f"{name}.toc"
    lines = toc.read_text(encoding="utf-8-sig").splitlines()
    version_line = next(line for line in lines if line.startswith("## Version:"))
    version = version_line.partition(":")[2].strip()
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+(?:[-.][A-Za-z0-9.-]+)?", version):
        raise ValueError(f"Invalid release version in {toc}")
    for line in lines:
        entry = line.strip()
        if entry and not entry.startswith("#") and not (source / entry.replace("\\", "/")).is_file():
            raise FileNotFoundError(f"Missing TOC entry {entry}")
    files = {
        path.relative_to(source).as_posix(): path for path in source.rglob("*")
        if path.is_file() and not any(part.startswith(".") for part in path.relative_to(source).parts)
    }
    if name == "AlwaysBuffed":
        files["LICENSE"] = ROOT / "LICENSE"
    suffix = "-forever" if "## AllowLoadGameType: camelot" in lines else ""
    return version, suffix, files


def package(name):
    version, suffix, files = release_files(name)
    out = ROOT / "dist" / f"{name}-{version}{suffix}.zip"
    out.parent.mkdir(exist_ok=True)
    with tempfile.TemporaryDirectory(dir=out.parent) as scratch:
        artifact = Path(scratch) / out.name
        with ZipFile(artifact, "w") as archive:
            for relative_path, path in sorted(files.items()):
                entry = ZipInfo(f"{name}/{relative_path}")
                entry.compress_type = ZIP_DEFLATED
                entry.external_attr = 0o100644 << 16
                archive.writestr(entry, path.read_bytes())
        with ZipFile(artifact) as archive:
            if archive.testzip():
                raise ValueError("Package failed its CRC check.")
        artifact.replace(out)
    return out


def install(archive_path, game, name):
    addons = game.resolve() / "Interface" / "AddOns"
    if not addons.is_dir():
        raise FileNotFoundError(f"WoW addon directory does not exist: {addons}")
    with ZipFile(archive_path) as archive:
        for member in archive.infolist():
            target = addons / member.filename
            target.parent.mkdir(parents=True, exist_ok=True)
            # Replace individual files atomically, including when updating an existing install.
            with tempfile.NamedTemporaryFile(dir=target.parent, delete=False) as staged:
                tmp = Path(staged.name)
            try:
                with archive.open(member) as src, tmp.open("wb") as dst:
                    shutil.copyfileobj(src, dst)
                tmp.replace(target)
            finally:
                tmp.unlink(missing_ok=True)
    return addons / name


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("action", choices=("build", "install"))
    parser.add_argument("addon", nargs="?", default="AlwaysBuffed")
    parser.add_argument("--game", type=Path, default=DEFAULT_GAME, help="WoW flavor folder containing Interface/AddOns")
    args = parser.parse_args()
    artifact = package(args.addon)
    print(artifact)
    if args.action == "install":
        print(install(artifact, args.game, args.addon))
