#!/bin/bash

# Copies headers of file
head -n 1 ./test.dat > ./test_modified.dat

# Counter variable
count=0

# Use awk to add 0.5 to the second field and print the modified line
tail -n +2 ./test.dat | while read -r line; do
    # Only modify the first 48 lines
    if [ $count -lt 48 ]; then
        echo "$line" | awk '{$2+=0.5; print $0}' >> ./test_modified.dat
        count=$((count+1))
    else
        echo "$line" >> ./test_modified.dat
    fi
done

# Formats modified .dat file into a table column format.
column -t ./test_modified.dat | tee ./test_modified.dat
