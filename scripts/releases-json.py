"""
Generate a releases.json entry for a new firmware version.

Expects that the binaries have the correct names and are placed in the correct directories,
incl. translation blobs.

Usage:

    cd scripts
    poetry install
    poetry run python releases-json.py 2.8.1 --changelog=changelog.txt

You need `prettier` on your system. For example: `nix-shell -p nodePackages.prettier`.

This will scan all models for a newly added version 2.8.1 and generate the corresponding
entries. If a bootloader is updated, you still have to edit releases.json manually,
or provide the new bootloader version with the --bootloader-version option.

You can interactively select the changelog entries that do not belong in btconly.

MISSING FEATURES:
* T1B1 is not supported. It should be enough to add an entry to BOOTLOADER_MIN
  and FIRMWARE_MIN, maybe.

The changelog format is as copypasted from notion. Expected format:

------------------
### T3T1 **[2.8.1] (21th August 2024)**

**Added**

- Added PIN keyboard animation. [#3885](https://github.com/trezor/trezor-firmware/pull/3885)
- Added menu entry animation. [#3896](https://github.com/trezor/trezor-firmware/pull/3896)
- Added screen brightness settings. [#3969](https://github.com/trezor/trezor-firmware/pull/3969)

**Fixed**

- Fixed title sometimes not fitting into result screen. [#4023](https://github.com/trezor/trezor-firmware/pull/4023)

### T2T1 **[2.8.1] (21th August 2024)**

**Fixed**

- Fixed displaying of a progress indicator for the formatting operation. [#3035](https://github.com/trezor/trezor-firmware/pull/3035)
------------------
"""

from __future__ import annotations

import json
import subprocess
import re
import typing as t
from pathlib import Path

import click
import requests
import questionary as q
from trezorlib import firmware

ROOT = Path(__file__).parent.parent.resolve()

FW_DATA = ROOT / "firmware"

RELEASES = "releases.json"

BOOTLOADER_MIN = {
    "T3T1": (2, 1, 6),
    "T3B1": (2, 1, 7),
    "T2T1": (2, 0, 0),
    "T2B1": (2, 1, 1),
    "T3W1": (2, 1, 13),
}

FIRMWARE_MIN = {
    "T3T1": (2, 7, 2),
    "T3B1": (2, 8, 3),
    "T2T1": (2, 0, 8),
    "T2B1": (2, 6, 1),
    "T3W1": (2, 9, 3),
}

MIN_BRIDGE_VERSION = (2, 0, 7)

FOUR_SPACE_INDENT = {"T2T1", "T1B1"}

TRAILING_MARKDOWN_LINK = re.compile(r"\s*\[#\d+\]\(.*?\)\s*$")


def splitversion(version: str) -> list[int]:
    return [int(x) for x in version.split(".")]


def joinversion(version: list[int]) -> str:
    return ".".join(str(x) for x in version)


def json_write(model: str, data: dict, path: Path):
    json_str = json.dumps(data, ensure_ascii=False)
    prettier_cmd = ["prettier", "--print-width=100", "--parser=json"]
    if model in FOUR_SPACE_INDENT:
        prettier_cmd.append("--tab-width=4")
    pretty_json = subprocess.check_output(prettier_cmd, input=json_str, text=True)
    path.write_text(pretty_json)


def parse_changelog(
    model: str, source: t.TextIO, univ_only_entries: set[str]
) -> tuple[str, str]:
    entries = []

    source.seek(0)
    lines = iter(source)
    for line in lines:
        if not line.startswith("###"):
            continue
        _leadin, section, *_rest = line.split()
        if section == model:
            break
    else:
        raise ValueError(f"Model {model} not found in changelog")

    for line in lines:
        if line.startswith("###"):
            break
        if not line.startswith("- "):
            continue
        line = line[2:].strip()
        line = TRAILING_MARKDOWN_LINK.sub("", line)
        entries.append("* " + line)

    selected = q.checkbox(
        "Browse changelog entries",
        [q.Choice(entry, checked=entry not in univ_only_entries) for entry in entries],
        instruction="Unmark the entries that should be excluded from Bitcoin-only changelog.\nSpace to mark/unmark, Enter to confirm.",
    ).ask()

    # remove from btconly_entries those that the user re-selected:
    univ_only_entries -= set(selected)
    # add those that have been deselected
    deselected = set(entries) - set(selected)
    univ_only_entries.update(deselected)

    btconly_entries = [entry for entry in entries if entry not in univ_only_entries]

    return ("\n".join(entries), "\n".join(btconly_entries))


def find_revision(version: str) -> str:
    FIRMWARE_REF_TAG_QUERY = (
        "https://api.github.com/repos/trezor/trezor-firmware/git/refs/tags/{tag}"
    )
    FIRMWARE_SIGNED_TAG_QUERY = (
        "https://api.github.com/repos/trezor/trezor-firmware/git/tags/{sha}"
    )

    if version.startswith("2"):
        tag = f"core/v{version}"
    else:
        tag = f"trezor-suite/v{version}"

    r = requests.get(FIRMWARE_REF_TAG_QUERY.format(tag=tag))
    r.raise_for_status()
    data = r.json()

    # signed tags have one more level of indirection
    if data["object"]["type"] == "tag":
        r = requests.get(FIRMWARE_SIGNED_TAG_QUERY.format(sha=data["object"]["sha"]))
        r.raise_for_status()
        data = r.json()

    assert data["object"]["type"] == "commit"
    return data["object"]["sha"]


def refresh_model(
    model: str,
    version: list[int],
    bootloader_version: list[int],
    revision: str,
) -> dict | None:
    model_str = model.lower()
    version_str = joinversion(version)
    model_univ = FW_DATA / model_str / f"trezor-{model_str}-{version_str}.bin"
    model_btconly = (
        FW_DATA / model_str / f"trezor-{model_str}-{version_str}-bitcoinonly.bin"
    )
    if not model_univ.exists() and not model_btconly.exists():
        return None

    fw_univ = firmware.parse(model_univ.read_bytes())
    fingerprint_univ = fw_univ.digest().hex()

    languages = []
    for tr in (FW_DATA / "translations" / model_str).glob("*.bin"):
        _translation, _model, lang, country, lang_version = tr.stem.split("-")
        if lang_version != version_str:
            continue
        languages.append(f"{lang}-{country}")

    result = {
        "required": False,
        "version": version,
        "min_bridge_version": MIN_BRIDGE_VERSION,
        "min_bootloader_version": BOOTLOADER_MIN[model],
        "min_firmware_version": FIRMWARE_MIN[model],
        "bootloader_version": bootloader_version,
        "firmware_revision": revision,
        "translations": sorted(languages),
        "url": "data/" + str(model_univ.relative_to(ROOT)),
        "fingerprint": fingerprint_univ,
        "changelog": "",
    }

    if model_btconly.exists():
        fw_btconly = firmware.parse(model_btconly.read_bytes())
        fingerprint_btconly = fw_btconly.digest().hex()
        result["url_bitcoinonly"] = "data/" + str(model_btconly.relative_to(ROOT))
        result["fingerprint_bitcoinonly"] = fingerprint_btconly
        result["changelog_bitcoinonly"] = ""

    return result


def update_json(model: str, jsonfile: Path, data: dict) -> None:
    releases_data = json.loads(jsonfile.read_text())
    for idx, entry in enumerate(releases_data):
        if entry["version"] == data["version"]:
            releases_data[idx] = data
            break
    else:
        releases_data.insert(0, data)

    print("Updating", jsonfile, "...")
    json_write(model, releases_data, jsonfile)


@click.command()
@click.argument("version", type=splitversion)
@click.option("-c", "--changelog", type=click.File())
@click.option("-g", "--revision")
def refresh(version: list[int], changelog: t.TextIO | None, revision: str | None):
    univ_only_entries = set()

    if revision is None:
        revision = find_revision(joinversion(version))

    for model in FIRMWARE_MIN.keys():
        releases_json = FW_DATA / model.lower() / RELEASES
        releases_data = json.loads(releases_json.read_text())

        bootloader_version = releases_data[0]["bootloader_version"]

        data = refresh_model(model, version, bootloader_version, revision)
        if data is None:
            continue

        if changelog is not None:
            c_univ, c_btconly = parse_changelog(model, changelog, univ_only_entries)
            data["changelog"] = c_univ
            data["changelog_bitcoinonly"] = c_btconly

        update_json(model, releases_json, data)
        if model == "T2T1":
            releases_legacy = FW_DATA / "2" / RELEASES
            update_json(model, releases_legacy, data)
        if model == "T1B1":
            releases_legacy = FW_DATA / "1" / RELEASES
            update_json(model, releases_legacy, data)

    click.echo("Don't forget to check bootloader versions!")


if __name__ == "__main__":
    refresh()
