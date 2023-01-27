#!/bin/bash

# Copies headers of file
head -n 1 ./test1.pdb > ./test1_modified.pdb

# Counter variable
count=0

# Use awk to add 0.5 to the second field and print the modified line
tail -n +2 ./test1.pdb | while read -r line; do
    # Only modify the first 48 lines
    if [ $count -lt 48 ]; then
        echo "$line" | awk '{$2+=0.5; print $0}' >> ./test1_modified.pdb
        count=$((count+1))
    else
        echo "$line" >> ./test1_modified.pdb
    fi
done

# Formats modified .dat file into a table column format.
column -t ./test1_modified.pdb > ././test1_modified_formated.pdb
rm /f ./test1_modified.pdb
