# FIRMWARE

This folder contains all official firmware binaries with related translations, authenticity pubkeys, and metadata.

The contents of this folder are deployed to [https://data.trezor.io/](https://data.trezor.io/) by a [Github action](https://github.com/trezor/data/actions/workflows/deploy_data.yml).

The binaries and data are used by `trezorctl` and third parties, in some cases also by [Trezor Suite](https://github.com/trezor/trezor-suite).

The sub-folders are divided by internal model names. Folders 1 and 2 are copies of T1B1 and T2T1; they are kept here for backwards compatibility.

Firmware binaries can be downloaded manually from the repository and installed as custom firmware via Trezor Suite. If a Trezor Suite user performs a firmware hash check and their firmware is not up to date (i.e. not bundled in Suite), it is downloaded from [https://data.trezor.io/](https://data.trezor.io/). Note that during a firmware update or a firmware type switch, both desktop and web Suite updates to the firmware version bundled in the app, not accessing the data available here.

File `releases.json` holds metadata related to all available firmware versions. Trezor Suite does not access it directly; instead, it includes a copy of this file with some changes in paths (dropping the `data/` prefix) and with the omission of some properties.

File `authenticity.json` is the source of truth for public keys used in the device authenticity check. This feature is ony available for devices with a secure element, i.e. not T1B1 and T2T1. File `authenticity-dev.json` holds debug keys to be used in conjunction with [Trezor Emulator](https://github.com/trezor/trezor-user-env). The keys are regularly copied to Trezor Suite by a [Github action](https://github.com/trezor/trezor-suite/actions/workflows/update-connect-config.yml) so that they can be accessed offline.

Folder `translations` holds translation blobs. These are not available for T1B1 and older firmware versions. Trezor Suite downloads translations from [https://data.trezor.io/](https://data.trezor.io/). During the initial firmware installation, Suite downloads and installs a firmware translation corresponding to the Suite language, if available. The file is silently updated during subsequent firmware installations or any call to Trezor Connect, if needed. If a translation download fails, no error is shown and the outdated version is kept, which may result in some strings not being translated.
