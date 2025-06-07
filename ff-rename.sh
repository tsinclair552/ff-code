#!/bin/bash
# Code contributed by ChatGPT-4o

# Check if the correct number of arguments is provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <source_directory> <target_directory>"
    exit 1
fi

SOURCE_DIR="$1"
TARGET_DIR="$2"

# Check if the source and target directories exist
if [ ! -d "$SOURCE_DIR" ]; then
    echo "Source directory does not exist: $SOURCE_DIR"
    exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
    echo "Target directory does not exist: $TARGET_DIR"
    exit 1
fi

# Get the list of files in the source and target directories
source_files=("$SOURCE_DIR"/*)
target_files=("$TARGET_DIR"/*)

# Check if the number of files in both directories is the same
if [ "${#source_files[@]}" -ne "${#target_files[@]}" ]; then
    echo "The number of files in source and target directories do not match."
    exit 1
fi

# Rename files in the source directory to match the target directory
for i in "${!source_files[@]}"; do
    source_file="${source_files[$i]}"
    target_file="${target_files[$i]}"

    # Extract the new filename from the target file
    new_filename=$(basename "$target_file")

    # Rename the source file
    mv "$source_file" "$SOURCE_DIR/$new_filename"
done

echo "Files renamed successfully."
