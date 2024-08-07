#!/usr/bin/env bash

PARENT_PATH=$( cd "$(dirname "${BASH_SOURCE[0]}")" || exit ; pwd -P )

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [[ $# -ne 1 ]]
    then
        echo "must provide 1 argument. $# provided"
        exit 1
fi

DEVICE=$1

extract_filenames_from_json() {
  local json_file="$1"

  # Filter out 
  #   a) 'null' from missing .url_bitcoinonly for older firmwares
  #   b) super-old firmwares

  jq -r '.[] | select(.url) | .url, .url_bitcoinonly' "$json_file" | xargs -n 1 basename | sort | uniq \
    | grep -vFf <(cat << EOF
null
trezor-1.0.0.bin
trezor-1.1.0.bin
trezor-1.2.0.bin
trezor-1.2.1.bin
trezor-1.3.0.bin
trezor-1.3.1.bin
trezor-1.3.2.bin
trezor-1.3.3.bin
trezor-1.3.4.bin
trezor-1.3.5.bin
trezor-t1b1-1.0.0.bin
trezor-t1b1-1.1.0.bin
trezor-t1b1-1.2.0.bin
trezor-t1b1-1.2.1.bin
trezor-t1b1-1.3.0.bin
trezor-t1b1-1.3.1.bin
trezor-t1b1-1.3.2.bin
trezor-t1b1-1.3.3.bin
trezor-t1b1-1.3.4.bin
trezor-t1b1-1.3.5.bin
EOF
)
}

list_files_in_directory() {
  local dir="$1"
  find "$dir" -type f -name "*.bin" -exec basename {} \; | sort \
    | grep -v "trezor-inter-" | grep -v "trezor-t1tb-inter-" # filer out Intermediary firmwares
}

compare_files() {
  local json_file="$1"
  local directory="$2"

  expected_files=$(extract_filenames_from_json "$json_file")
  actual_files=$(list_files_in_directory "$directory")

  missing_files=$(comm -23 <(echo "$expected_files") <(echo "$actual_files"))
  extra_files=$(comm -13 <(echo "$expected_files") <(echo "$actual_files"))

  if [[ -z "$missing_files" && -z "$extra_files" ]]; then
    echo -e "${GREEN}All files are present and accounted for.${NC}"
  else
    if [[ -n "$missing_files" ]]; then
      echo -e "${RED}Missing files:"
      echo "$missing_files" | awk '{print "    " $0}'
      echo -e "${NC}"
    fi
    if [[ -n "$extra_files" ]]; then
      echo -e "${RED}Extra files in directory:"
      echo "$extra_files" | awk '{print "    " $0}'
      echo -e "${NC}"
    fi

    exit 1
  fi
}

json_file=$PARENT_PATH"/../firmware/"$DEVICE/"releases.json"
directory=$PARENT_PATH"/../firmware/"$DEVICE

echo "Checking directory: $directory"

compare_files "$json_file" "$directory"
