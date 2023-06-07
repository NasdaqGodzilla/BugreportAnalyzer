#!/bin/bash

# Extract and get bugreport
# Input: path of bugreport.zip; extract path
# Output: path of dump file
function zip_bugreport_extract() {
    local path_bugreportzip="$1"
    local path_extract="$2"
    local path_extract_subpath=`echo -e "$path_bugreportzip" | sed -e 's/\.zip$//g; s/\//_/g'`
    path_extract="$path_extract/$path_extract_subpath"
    local path_entry="$path_extract/main_entry.txt"

    # echo -e "Extracting: $path_bugreportzip to $path_extract"

    mkdir -p "$path_extract"

    unzip -qu "$path_bugreportzip" main_entry.txt -d "$path_extract"

    local dumpfile=`cat "$path_entry"`
    rm -rf "$path_entry"
    unzip -qu "$path_bugreportzip" "$dumpfile" -d "$path_extract"

    # echo -e "Extracting: $path_extract/$dumpfile"

    echo -e "$path_extract/$dumpfile"
}
