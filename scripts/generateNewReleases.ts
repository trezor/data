// This script is to modify releases.json to new format <device-model>-<version>-<firmware-type>.json
// You can run the script like: "bun scripts/generateNewReleases.ts"
// Once the json files are generated they can be formated with:
// prettier --write "{suite,scripts}/**/*.{json,ts}"

import fs from "fs";
import path from "path";
import { promisify } from "util";

const readFile = promisify(fs.readFile);
const writeFile = promisify(fs.writeFile);

interface Release {
  required: boolean;
  version: [number, number, number];
  bootloader_version: [number, number, number];
  min_bridge_version: [number, number, number];
  min_firmware_version: [number, number, number];
  min_bootloader_version: [number, number, number];
  url: string;
  url_bitcoinonly: string;
  fingerprint: string;
  fingerprint_bitcoinonly: string;
  firmware_revision: string;
  notes: string;
  changelog: string;
  changelog_bitcoinonly: string;
}

type ReleaseFormatted = Omit<
  Release,
  | "notes"
  | "changelog_bitcoinonly"
  | "fingerprint_bitcoinonly"
  | "url_bitcoinonly"
>;

const FW_DATA = "../firmware";

const transformReleases = async (deviceModel: string) => {
  const dirPath = path.join(
    __dirname,
    `${FW_DATA}/${deviceModel}/releases.json`
  );
  console.log("Reading from:", dirPath);

  try {
    const fileContent = await readFile(dirPath, { encoding: "utf8" });
    const releases: Release[] = JSON.parse(fileContent);
    console.log(`Found ${releases.length} releases for ${deviceModel}.`);

    const universalOutputDirPath = path.join(
      __dirname,
      "..",
      "suite",
      "firmware",
      deviceModel,
      "universal"
    );
    await fs.promises.mkdir(universalOutputDirPath, { recursive: true });
    const bitcoinonlyOutputDirPath = path.join(
      __dirname,
      "..",
      "suite",
      "firmware",
      deviceModel,
      "bitcoinonly"
    );
    await fs.promises.mkdir(bitcoinonlyOutputDirPath, { recursive: true });

    for (const release of releases) {
      const universalFileName = `${deviceModel}-${release.version.join(
        "."
      )}-universal.json`;
      const universalBinName = `${deviceModel}-${release.version.join(
        "."
      )}-universal.bin`;
      const universalOutputPath = path.join(
        universalOutputDirPath,
        universalFileName
      );

      const universalJson: ReleaseFormatted = {
        required: release.required,
        version: release.version,
        bootloader_version: release.bootloader_version,
        min_bridge_version: release.min_bridge_version,
        min_firmware_version: release.min_firmware_version,
        min_bootloader_version: release.min_bootloader_version,
        url: `/suite/firmware/${deviceModel}/universal/${universalBinName}`,
        fingerprint: release.fingerprint,
        firmware_revision: release.firmware_revision,
        changelog: release.changelog,
      };

      const universalJsonString = JSON.stringify(universalJson, null, 2);
      await writeFile(universalOutputPath, universalJsonString, {
        encoding: "utf8",
      });
      console.log(`Generated for universal file: ${universalOutputPath}`);

      if (release.fingerprint_bitcoinonly) {
        const bitcoinonlylFileName = `${deviceModel}-${release.version.join(
          "."
        )}-bitcoinonly.json`;
        const bitcoinonlylBinName = `${deviceModel}-${release.version.join(
          "."
        )}-bitcoinonly.bin`;
        const bitcoinonlyOutputPath = path.join(
          bitcoinonlyOutputDirPath,
          bitcoinonlylFileName
        );

        const bitcoinonlyJson: ReleaseFormatted = {
          required: release.required,
          version: release.version,
          bootloader_version: release.bootloader_version,
          min_bridge_version: release.min_bridge_version,
          min_firmware_version: release.min_firmware_version,
          min_bootloader_version: release.min_bootloader_version,
          url: `/suite/firmware/${deviceModel}/universal/${bitcoinonlylBinName}`,
          fingerprint: release.fingerprint_bitcoinonly,
          firmware_revision: release.firmware_revision,
          changelog: release.changelog_bitcoinonly,
        };

        const bitcoinonlyJsonString = JSON.stringify(bitcoinonlyJson, null, 2);
        await writeFile(bitcoinonlyOutputPath, bitcoinonlyJsonString, {
          encoding: "utf8",
        });
        console.log(`Generated for bitcoinonly file: ${bitcoinonlyOutputPath}`);
      }
    }

    console.log("All release files generated successfully!");
  } catch (error) {
    console.error("Error processing releases:", error);
  }
};

const deviceModels = ["T1B1", "T2T1", "T2B1", "T3B1", "T3T1", "T3W1"];

for (const deviceModel of deviceModels) {
  transformReleases(deviceModel.toLowerCase());
}
