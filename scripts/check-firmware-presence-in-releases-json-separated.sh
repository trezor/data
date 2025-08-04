#!/usr/bin/env bash

PARENT_DIR="firmware"
EXCLUDED_DIR="translations"

TARGET_DIRS=()

while IFS= read -r dir; do
    TARGET_DIRS+=("$dir/")
done < <(find "$PARENT_DIR" -mindepth 2 -maxdepth 2 -type d ! -path "*$EXCLUDED_DIR*")

MISSING_FILES_COUNT=0
FILES_CHECKED_COUNT=0

for TARGET_DIR in "${TARGET_DIRS[@]}"; do

    if [ ! -d "$TARGET_DIR" ]; then
        echo "Error: Directory '$TARGET_DIR' not found. Skipping."
        echo "-------------------------------------"
        exit 1
    fi

    echo "Checking JSON file URLs in: $TARGET_DIR"
    echo "-------------------------------------"

    if ! ls "$TARGET_DIR"/*.json 1> /dev/null 2>&1; then
        echo "No .json files found in this directory."
        exit 1
    fi

    for JSON_FILE in "$TARGET_DIR"/*.json; do

        ((FILES_CHECKED_COUNT++))

        URL_PATH=$(jq -r '.url' "$JSON_FILE")

        if [ -z "$URL_PATH" ] || [ "$URL_PATH" == "null" ]; then
            echo " No 'url' key found or its value is null in $JSON_FILE."
            ((MISSING_FILES_COUNT++))
            continue
        fi

        if [ -f "$URL_PATH" ]; then
            echo "OK - File exists at '$URL_PATH' (from $JSON_FILE)"
        else
            ((MISSING_FILES_COUNT++))
            echo "NOT FOUND - File does not exist at '$URL_PATH' (from $JSON_FILE)"
        fi


        if ! jq -e '.translations | objects' "$JSON_FILE" > /dev/null; then
            echo "Error: Key 'translations' not found or is not a JSON object in $JSON_FILE."
            exit 1
        fi

        echo "Checking for translation files..."

        while IFS= read -r filepath; do
            if [ -z "$filepath" ] || [ "$filepath" == "null" ]; then
                echo "WARNING: Found a null or empty path in JSON."
                ((MISSING_FILES_COUNT++))
                continue
            fi

            if [ -f "$filepath" ]; then
                echo "OK - File exists at '$filepath'"
            else
                ((MISSING_FILES_COUNT++))
                echo "NOT FOUND - Translation file does not exist at '$filepath'"
            fi
        done < <(jq -r '.translations.[]' "$JSON_FILE")
    done
    echo ""
done

echo "-------------------------------------"
echo "Check complete."
echo ""
echo "Total JSON files checked: $FILES_CHECKED_COUNT"
if [ "$MISSING_FILES_COUNT" -eq 0 ]; then
    echo "All binary files were found!"
else
    echo "ERROR: Total missing files: $MISSING_FILES_COUNT"
    exit 1
fi
