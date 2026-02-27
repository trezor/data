# T2T1 — Trezor Model T

This directory contains firmware binaries and release metadata for the **Trezor Model T**. It is also accessible as directory `2` for backwards compatibility.

## Files

Firmware binaries follow the naming convention `trezor-t2t1-{version}.bin` for the universal build and `trezor-t2t1-{version}-bitcoinonly.bin` for the Bitcoin-only build. Note that early releases (prior to 2.1.5) do not have a Bitcoin-only variant.

### Release metadata

- `releases.json` — legacy index of all releases, kept for backwards compatibility.
- `universal/` — per-release JSON files for the universal (multi-coin) firmware, e.g. `t2t1-2.10.0-universal.json`.
- `bitcoinonly/` — per-release JSON files for the Bitcoin-only firmware, e.g. `t2t1-2.10.0-bitcoinonly.json`.

Each per-release JSON file contains version info, minimum version requirements, firmware fingerprint, changelog, and translation blob URLs for supported languages.
