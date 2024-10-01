#!/bin/bash
# gen_pregit_mtime(){

# This script iterates over each file name provided as an argument,
# captures its original modification time, and outputs a touch command
# to reset the file's modification time to its original value.

# USAGE: (ignores hidden .file and .dirs in pwd)
#     find * -type f -print0 | gen_pregit_mtime.sh | sort -z -k5,5 | tr "\0" "\n" > pregit_mtime.sh
# BUGS:
#     Only tested in Linux
#     Cannot handle single quotes with double quotes in filename

# for file in "$@"; do
    qq='"'
    while IFS= read -r -d '' file; do
        # Check OS type to determine the correct stat command syntax
        if [[ "$OSTYPE" == "darwin"* ]]; then
            # macOS uses BSD stat, format differs
            mod_time=$(stat -f "%Sm" -t "%Y%m%d%H%M.%S" "$file")
        else
            # Assuming GNU stat for Linux and Cygwin - 2024-03-12 17:19:18.405487095 +1000
            mod_time=$(stat --format "%y" "$file" | sed "s/-//; s/-//; s/ //; s/://; s/[.].*//; s/:/./")
        fi

        if [ ! -z "$mod_time" ]; then
            # Generate and output the touch command
            case "$file" in
                (*"'"*) printf "%s\0" "touch -m -t $mod_time $qq$file$qq";;
                (*)     printf "%s\0" "touch -m -t $mod_time '$file'";;
            esac
        else
            echo "Error: Could not retrieve modification time for '$file'." 1>&2
        fi
    done
# }