#!/usr/bin/env python3

import os
import json
import struct


def check_bridge():
    patterns = [
        "index.html",
        "trezor-bridge-%(version)s-1.i386.rpm",
        "trezor-bridge-%(version)s-1.x86_64.rpm",
        "trezor-bridge_%(version)s_amd64.deb",
        "trezor-bridge_%(version)s_i386.deb",
        "trezor-bridge-%(version)s-win32-install.exe",
        "trezor-bridge-%(version)s-win32-install.exe.asc",
        "trezor-bridge-%(version)s.pkg",
        "trezor-bridge-%(version)s.pkg.asc",
    ]

    print("Checking Bridge data:")

    v = open("bridge/latest.txt", "r").read().strip()
    print("* expected latest version: %s" % v)

    if not os.path.isdir(os.path.join("bridge", v)):
        return False

    ok = True
    print("* checking files for version: %s" % v)
    for p in patterns:
        expected = p % {"version": v}
        fname = os.path.join("bridge", v, expected)
        print("   * %s ... " % fname, end="")
        if os.path.isfile(fname):
            print("OK")
        else:
            ok = False
            print("MISSING")

    print()
    return ok


def check_firmware(model, bitcoin_only=False):

    if model not in ["1", "2"]:
        raise ValueError("Unknown model: %s" % model)

    print("Checking Firmware (model %s) data:" % model)

    ok = True
    releases = json.load(open("firmware/%s/releases.json" % model, "r"))

    # Find out the latest firmware release
    latest = [0, 0, 0]
    for r in releases:
        latest = max(latest, r["version"])

    print("* expected latest version: %s" % ".".join(str(x) for x in latest))

    for r in releases:
        # Check only latest firmware, others may not be available
        if r["version"] != latest:
            continue

        firmware = r["url_bitcoinonly"] if bitcoin_only else r["url"]
        version = ".".join([str(x) for x in r["version"]])

        if version not in firmware:
            print("Missing '%s' in '%s'" % (version, firmware))
            ok = False
            continue

        print("  * %s ... " % firmware, end="")

        if not os.path.exists(firmware[len("data/") :]):
            print("MISSING")
            ok = False
            continue
        else:
            data = open(firmware[len("data/") :], "rb").read()

        if model == "1":
            start = b"TRZR"
        elif model == "2":
            start = b"TRZV"

        if not data.startswith(start):
            print("WRONG HEADER")
            ok = False
            continue

        if model == "1":
            codelen = struct.unpack("<I", data[4:8])
            codelen = codelen[0]

            if codelen + 256 != len(data):
                print(
                    "INVALID SIZE (is %d bytes, should be %d bytes)"
                    % (codelen + 256, len(data))
                )
                ok = False
                continue

            elif len(data) > 1024 * 1024 - 32 * 1024:  # Firmware - header - signatures
                print("TOO BIG")
                ok = False
                continue

            else:
                print("OK")

        if model == "2":
            vendorlen = struct.unpack("<I", data[4:8])[0]
            headerlen = struct.unpack("<I", data[4 + vendorlen : 8 + vendorlen])[0]
            codelen = struct.unpack("<I", data[12 + vendorlen : 16 + vendorlen])[0]

            expected_len = codelen + vendorlen + headerlen
            if expected_len != len(data):
                print(
                    "INVALID SIZE (is %d bytes, should be %d bytes)"
                    % (expected_len, len(data))
                )
                ok = False
                continue

            else:
                print("OK")

    print()
    return ok


if __name__ == "__main__":

    ok = True

    ok &= check_bridge()
    ok &= check_firmware("1")
    ok &= check_firmware("1", bitcoin_only=True)
    ok &= check_firmware("2")
    ok &= check_firmware("2", bitcoin_only=True)

    if ok:
        print("EVERYTHING OK")
        exit(0)
    else:
        print("PROBLEMS FOUND")
        exit(1)
