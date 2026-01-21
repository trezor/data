"""
Copies firmware binaries, translations and JSONs from a local copy of `trezor-suite-firmware-release`.

Also, renames the files according to the naming convention in this repo, trezor-<model>-<version>(-bitcoinonly)?.bin

Usage:

    nix-shell
    python scripts/copy-firmware-jsons.py 2.9.1 -r ../trezor-suite-firmware-release/

"""

from __future__ import annotations

import json
import typing as t
import subprocess
import shutil
import re
from pathlib import Path

import click

ROOT = Path(__file__).parent.parent.resolve()

FW_DATA = ROOT / "firmware"


def copy_single_file(model_dir: Path, pattern: str, dst: Path) -> None:
    paths = list(model_dir.glob(pattern))
    if len(paths) > 1:
        raise click.ClickException(
            f"{model_dir / pattern} matches {len(paths)} files", paths
        )

    if paths:
        copy_file(src=paths[0], dst=dst)


def copy_and_adapt_json(src: Path, dst: Path, new_url: Path) -> dict:
    if not src.exists():
        return

    click.echo(f"\t{src} → {dst}")
    data = json.load(src.open())

    # overwrite "url" since the binary has been renamed
    data["url"] = str(new_url)

    translations = data.get("translations", {})
    # drop "signed/" subdirectory from translations' URLs
    data["translations"] = {
        key: re.sub("^firmware/signed/", "firmware/", value)
        for key, value in translations.items()
    }

    json_write(data=data, path=dst)
    return data


def update_releases_json(
    releases_json_path: Path, universal_json: dict | None, btconly_json: dict | None
) -> None:
    """
    Add a new entry to `releases.json`.

    It is currently used by some CLI tools in https://github.com/trezor/trezor-firmware.
    Not used anymore by Trezor Suite.
    """
    if universal_json is None and btconly_json is None:
        return

    shared_keys = [
        "required",
        "version",
        "min_bridge_version",
        "min_bootloader_version",
        "min_firmware_version",
        "bootloader_version",
        "firmware_revision",
    ]
    non_shared_keys = ["url", "fingerprint", "changelog"]

    universal_shared = {k: universal_json[k] for k in shared_keys}
    btconly_shared = {k: btconly_json[k] for k in shared_keys}
    assert universal_shared == btconly_shared

    new_item = dict(universal_shared)

    # T1B1 doesn't have translations
    assert universal_json.get("translations") == btconly_json.get("translations")
    if (translations := universal_json.get("translations")) is not None:
        new_item["translations"] = list(translations)  # keep only the keys

    for suffix, items in [("", universal_json), ("_bitcoinonly", btconly_json)]:
        for k in non_shared_keys:
            value = items[k]
            if k == "url":
                # adapt URL prefix to the existing convention
                value = re.sub("^firmware/", "data/firmware/", value)
            new_item[k + suffix] = value

    data = json.load(releases_json_path.open())

    for i, item in enumerate(data):
        if item["version"] == new_item["version"]:
            data[i] = new_item
            break
    else:
        data.insert(0, new_item)

    json_write(data, releases_json_path)


def json_write(data: dict, path: Path, *extra_flags: str) -> None:
    json_str = json.dumps(data, ensure_ascii=False)
    prettier_cmd = ["prettier", "--print-width=100", "--parser=json"]
    pretty_json = subprocess.check_output(prettier_cmd, input=json_str, text=True)
    path.write_text(pretty_json)


def copy_file(src: Path, dst: Path) -> None:
    click.echo(f"\t{src} → {dst}")
    shutil.copy(src=src, dst=dst)


@click.command()
@click.argument("version")
@click.option(
    "-r", "--release-repo", type=Path, default="../trezor-suite-firmware-release/"
)
def main(version: str, release_repo: Path):
    signed = release_repo / "firmware" / "signed"
    if not signed.exists():
        raise click.ClickException(f"{signed} is missing")

    for model_src in sorted(signed.glob("t?[btw]?")):
        model_name = model_src.name.lower()

        # copy signed binaries while matching naming convention
        click.secho(f"\n{model_name} binaries", bold=True)
        model_dst = FW_DATA / model_name
        universal_dst = model_dst / f"trezor-{model_name}-{version}.bin"
        copy_single_file(
            model_src,
            f"firmware-{model_name.upper()}-{version}-*-signed.bin",
            universal_dst,
        )
        btconly_dst = model_dst / f"trezor-{model_name}-{version}-bitcoinonly.bin"
        btconly = "bitcoinonly" if model_name == "t1b1" else "btconly"
        copy_single_file(
            model_src,
            f"firmware-{model_name.upper()}-{btconly}-{version}-*-signed.bin",
            btconly_dst,
        )

        # copy signed translations (no renaming is needed) for this version
        click.secho(f"{model_name} translations", bold=True)
        translations_src = signed / "translations" / model_name
        translations_dst = FW_DATA / "translations" / model_name
        blob_pattern = f"translation-{model_name.upper()}-??-??-{version}.bin"
        for blob in sorted(translations_src.glob(blob_pattern)):
            copy_file(blob, translations_dst / blob.name)

        # copy and adapt JSONs
        click.secho(f"{model_name} JSONs", bold=True)
        universal_json = copy_and_adapt_json(
            model_src / "universal" / f"{model_name}-{version}-universal.json",
            model_dst / "universal" / f"{model_name}-{version}-universal.json",
            new_url=universal_dst.relative_to(ROOT),
        )
        btconly_json = copy_and_adapt_json(
            model_src / "bitcoinonly" / f"{model_name}-{version}-bitcoinonly.json",
            model_dst / "bitcoinonly" / f"{model_name}-{version}-bitcoinonly.json",
            new_url=btconly_dst.relative_to(ROOT),
        )
        update_releases_json(model_dst / "releases.json", universal_json, btconly_json)


if __name__ == "__main__":
    main()
