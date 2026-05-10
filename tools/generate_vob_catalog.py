#!/usr/bin/env python3
import argparse
import re
import xml.etree.ElementTree as ET
from pathlib import Path
from urllib.request import urlopen

SUPPORTED_EXTS = {".3DS", ".MRM", ".MMB", ".MDL", ".MDS", ".ASC"}
MESH_DIR_NAMES = {"MESHES", "ANIMS"}
VOBBILDER_URL = "https://drakaniaverse.com.pl/vobbilder/neue_daten.js"


def squirrel_string(value: str) -> str:
    return '"' + value.replace('\\', '\\\\').replace('"', '\\"') + '"'


def normalize_name(value: str) -> str:
    name = Path(value.replace('\\', '/')).name.strip().upper()
    return name


def instance_from_visual(visual: str) -> str:
    return Path(visual).stem.upper()


def preview_for_visual(visual: str) -> str:
    path = normalize_name(visual)
    stem = Path(path).stem.upper()
    ext = Path(path).suffix.upper()
    if ext == ".3DS":
        return stem + ".MRM"
    return path


def world_visual_for_file(path: Path) -> str:
    stem = path.stem.upper()
    ext = path.suffix.upper()
    if ext == ".MRM":
        return stem + ".3DS"
    return stem + ext


def add_entry(entries: dict, instance: str, name: str, visual: str, source: str, category: str = "", asset_path: str = "") -> None:
    visual = normalize_name(visual)
    if not visual:
        return
    ext = Path(visual).suffix.upper()
    if ext not in SUPPORTED_EXTS:
        return
    key = instance.strip().upper() if instance else instance_from_visual(visual)
    if not key:
        return
    preview = preview_for_visual(visual)
    existing = entries.get(key)
    entry = {
        "instance": key,
        "name": name.strip() if name else key,
        "visual": visual,
        "previewVisual": preview,
        "source": source,
    }
    if category:
        entry["category"] = category
    if asset_path:
        entry["assetPath"] = asset_path
    if existing is None:
        entries[key] = entry
        return
    if existing["source"] == "data.xml" and source != "data.xml":
        return
    if existing["visual"].endswith(".MRM") and visual.endswith(".3DS"):
        entries[key] = entry


def parse_data_xml(path: Path, entries: dict) -> None:
    if not path.exists():
        return
    root = ET.parse(path).getroot()
    for item in root.findall(".//items/item"):
        instance = (item.findtext("instance") or "").strip().upper()
        visual = (item.findtext("visual") or "").strip().upper()
        name = (item.findtext("name") or instance).strip()
        add_entry(entries, instance, name, visual, "data.xml")


def should_scan_dir(path: Path) -> bool:
    parts = {part.upper() for part in path.parts}
    if "_COMPILED" in parts:
        return True
    return bool(parts & MESH_DIR_NAMES)


def scan_assets(root: Path, entries: dict) -> None:
    if not root.exists():
        return
    for path in root.rglob("*"):
        if not path.is_file():
            continue
        ext = path.suffix.upper()
        if ext not in SUPPORTED_EXTS:
            continue
        if not should_scan_dir(path.parent):
            continue
        visual = world_visual_for_file(path)
        instance = instance_from_visual(visual)
        add_entry(entries, instance, instance, visual, "assets")


def source_from_vobbilder_path(path: str, flags: int, category: str) -> str:
    lower = path.lower()
    if "addon" in lower or category == "Interactive":
        return "drakaniaverse:notr"
    if lower.startswith("g1/") or (flags & 1):
        return "drakaniaverse:g1"
    if lower.startswith("g2/") or (flags & 2) or (flags & 4):
        return "drakaniaverse:g2"
    return "drakaniaverse"


def read_text_from_path_or_url(value: str) -> str:
    if value.startswith("http://") or value.startswith("https://"):
        with urlopen(value, timeout=30) as response:
            return response.read().decode("utf-8", errors="replace")
    return Path(value).read_text(encoding="utf-8")


def parse_vobbilder(value: str, entries: dict) -> None:
    if not value:
        return
    try:
        text = read_text_from_path_or_url(value)
    except Exception:
        return
    category = ""
    category_re = re.compile(r'vobs\["([^"]+)"\]\s*=\s*new\s+Array\s*\(', re.IGNORECASE)
    entry_re = re.compile(r'new\s+Array\("([^"]*)"\s*,\s*"([^"]+)"\s*,\s*(-?\d+)\s*,\s*(-?\d+)\)', re.IGNORECASE)
    for line in text.splitlines():
        match_category = category_re.search(line)
        if match_category:
            category = match_category.group(1)
            continue
        match_entry = entry_re.search(line)
        if not match_entry:
            continue
        asset_path = match_entry.group(1).strip()
        name = match_entry.group(2).strip()
        flags = int(match_entry.group(4))
        visual = normalize_name(name + ".3ds")
        instance = instance_from_visual(visual)
        source = source_from_vobbilder_path(asset_path, flags, category)
        add_entry(entries, instance, instance, visual, source, category, asset_path)


def write_catalog(path: Path, entries: dict) -> None:
    rows = sorted(entries.values(), key=lambda row: (row["source"], row["instance"]))
    lines = [
        "phoenix.vob.Catalog <- [",
    ]
    for row in rows:
        lines.append(
            "\t{ instance = " + squirrel_string(row["instance"]) +
            ", name = " + squirrel_string(row["name"]) +
            ", visual = " + squirrel_string(row["visual"]) +
            ", previewVisual = " + squirrel_string(row["previewVisual"]) +
            ", source = " + squirrel_string(row["source"]) +
            ((", category = " + squirrel_string(row["category"])) if "category" in row else "") +
            ((", assetPath = " + squirrel_string(row["assetPath"])) if "assetPath" in row else "") +
            " },"
        )
    lines.append("]")
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text("\n".join(lines) + "\n", encoding="utf-8")


def main() -> None:
    parser = argparse.ArgumentParser(description="Generate Phoenix VOB catalog from data.xml and Gothic _WORK/DATA assets.")
    parser.add_argument("--data", default="data.xml", help="Path to generated G2O data.xml")
    parser.add_argument("--work", action="append", default=[], help="Path to Gothic _WORK/DATA or a server/resources tree to scan; can be repeated")
    parser.add_argument("--vobbilder", default="", help="Path or URL to Drakania vobbilder neue_daten.js")
    parser.add_argument("--download-vobbilder", action="store_true", help="Download the current Drakania vobbilder list")
    parser.add_argument("--out", default="gamemodes/phoenix/modules/vob/shared/catalog.nut", help="Output Squirrel catalog file")
    args = parser.parse_args()

    entries = {}
    parse_data_xml(Path(args.data), entries)
    for work in args.work:
        scan_assets(Path(work), entries)
    if args.download_vobbilder:
        parse_vobbilder(VOBBILDER_URL, entries)
    if args.vobbilder:
        parse_vobbilder(args.vobbilder, entries)
    write_catalog(Path(args.out), entries)


if __name__ == "__main__":
    main()
