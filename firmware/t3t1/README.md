# T3T1 — Trezor Safe 5

This directory contains firmware binaries and release metadata for the **Trezor Safe 5**.

## Files

Firmware binaries follow the naming convention `trezor-t3t1-{version}.bin` for the universal build and `trezor-t3t1-{version}-bitcoinonly.bin` for the Bitcoin-only build.

### Release metadata

- `releases.json` — legacy index of all releases, kept for backwards compatibility.
- `universal/` — per-release JSON files for the universal (multi-coin) firmware, e.g. `t3t1-2.10.0-universal.json`.
- `bitcoinonly/` — per-release JSON files for the Bitcoin-only firmware, e.g. `t3t1-2.10.0-bitcoinonly.json`.

Each per-release JSON file contains version info, minimum version requirements, firmware fingerprint, changelog, and translation blob URLs for supported languages.
