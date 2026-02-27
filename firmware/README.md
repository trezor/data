# Firmware

This directory contains all official firmware binaries with related translations, authenticity pubkeys, and metadata. The contents are deployed to [https://data.trezor.io/](https://data.trezor.io/) by a [Github action](https://github.com/trezor/data/actions/workflows/deploy_data.yml) and are used by `trezorctl`, [Trezor Suite](https://github.com/trezor/trezor-suite), and third parties.

## Directory structure

The sub-directorys are divided by internal model names. Directory 1 and 2 are copies of T1B1 and T2T1; they are kept here for backwards compatibility.

Each of the model directories in this repository (`firmware/t1b1/`, `firmware/t2b1/`, and so on) comes with a legacy `releases.json` and new per-release JSON files separated by `bitcoinonly` and `universal`, like: `firmware/t3w1/bitcoinonly/t3w1-2.10.0-bitcoinonly.json`, which defines the metadata of each firmware release.

## Firmware releases

Firmware binaries can be downloaded manually from the repository and installed as custom firmware via Trezor Suite or trezorctl. Trezor Suite comes with bundled firmware that is defined in [releases.v1.json](https://github.com/trezor/trezor-suite/blob/develop/packages/connect-data/files/firmware/release/releases.v1.json), but if the sequence in [remote signed releases.v1.json](https://data.trezor.io/firmware/config/releases.v1.json) is deployed with a higher version, then the firmware defined by it in this repository is going to be used by Trezor Suite. This system allows us to offer new firmware to Trezor Suite users without the need of a new Trezor Suite release.

Trezor Suite also bundles those release JSON files for each of the firmware binaries that it bundles, but when it uses the `remote signed release.v1.json`, it uses the files from this repository via `data.trezor.io`.

## Authenticity

File `authenticity.json` is the source of truth for public keys used in the device authenticity check. This feature is only available for devices with a secure element, i.e. not T1B1 and T2T1. File `authenticity-dev.json` holds debug keys to be used in conjunction with [Trezor Emulator](https://github.com/trezor/trezor-user-env).

## Translations

Directory `translations` holds translation blobs. These are not available for T1B1 and older firmware versions. Trezor Suite downloads translations from [https://data.trezor.io/](https://data.trezor.io/). During the initial firmware installation, Suite downloads and installs a firmware translation corresponding to the Suite language, if available. The file is silently updated during subsequent firmware installations or any call to Trezor Connect, if needed. If a translation download fails, no error is shown and the outdated version is kept, which may result in some strings not being translated.

## Models mapping

| Model | Name                |
| ----- | ------------------- |
| T1B1  | Trezor One          |
| T2T1  | Trezor Model T      |
| T2B1  | Trezor Safe 3 rev.A |
| T3B1  | Trezor Safe 3 rev.B |
| T3T1  | Trezor Safe 5       |
| T3W1  | Trezor Safe 7       |
