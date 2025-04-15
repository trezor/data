#!/usr/bin/env bash

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit ; pwd -P )

RED='\033[0;31m'
NC='\033[0m' # No Color

if [[ $# -ne 1 ]]
    then
        echo "must provide 1 argument. $# provided"
        exit 1
fi

DEVICE=$1

extract_file_paths_from_json() {
  local json_file="$1"

  # Filter out 'null' from missing .url_bitcoinonly for older firmwares

  jq -r '.[] | select(.url) | .url, .url_bitcoinonly' "$json_file" | xargs -n1 --no-run-if-empty | sort | uniq \
    | grep -vF "null"
}

list_files_in_directory() {
  local dir="$1"
  find "$dir" -type f -name "*.bin" -exec basename {} \; | sort \
    | grep -v "trezor-inter-" | grep -v "trezor-t1b1-inter-" # Filter out Intermediary firmwares
}

compare_files() {
  local json_file="$1"
  local directory="$2"

  # TEST 1: All files in releases.json exist

  files_in_releases_json=$(extract_file_paths_from_json "$json_file")

  all_exist=true
  for file in $files_in_releases_json; do
      file_to_test="$directory/../../../$file"
      if [ ! -e "$file_to_test" ]; then
          echo -e "${RED}File does not exist: $file_to_test${NC}"
          all_exist=false
      fi
  done

  if ! $all_exist ; then
      exit 1
  fi

  # TEST 2: All files in directory are in releases.json

  actual_files=$(list_files_in_directory "$directory") # All files in the directory
  full_path_actual_files=$(for i in $actual_files; do echo "data/firmware/${DEVICE}/${i}"; done) # Prefixed to match the expected format in releases.json
  extra_files=$(comm -13 <(echo "$files_in_releases_json") <(echo "$full_path_actual_files"))

  if [[ -n "$extra_files" ]]; then
    echo -e "${RED}Extra files in directory:"
    echo "$extra_files" | awk '{print "    " $0}'
    echo -e "${NC}"
    exit 1
  fi
}

json_file=$PARENT_PATH"/../firmware/"$DEVICE/"releases.json"
directory=$PARENT_PATH"/../firmware/"$DEVICE

echo "Checking directory: $directory"

if [[ ! -f "$json_file" && -z $(find "$directory" -type f -name "trezor-*.bin") ]]; then
    echo "Skipped, no releases.json or firmware binaries found in the directory."
    exit 0
fi

compare_files "$json_file" "$directory"
