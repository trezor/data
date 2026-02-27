# T1B1 — Trezor One

This directory contains firmware binaries and release metadata for the **Trezor One** (Legacy). It is also accessible as directory `1` for backwards compatibility.

## Files

Firmware binaries follow the naming convention `trezor-t1b1-{version}.bin` for the universal build and `trezor-t1b1-{version}-bitcoinonly.bin` for the Bitcoin-only build.

### Intermediate binaries

Files named `trezor-t1b1-inter-*.bin` are intermediate firmware used as stepping stones when upgrading from very old bootloader versions that cannot directly install a recent release.
