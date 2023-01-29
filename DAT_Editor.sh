#!/bin/bash

# Copies headers of file
head -n 1 ./test1.pdb > ./test1_mod.pdb

# Counter variable
count=0

# Use awk to add 0.5 to the second field and print the modified line
tail -n +2 ./test1.pdb | while read -r line; do
    # Only modify the first 48 lines
    if [ $count -lt 48 ]; then
        temp=$(echo $line | awk '{print $2}')
        total=$(bc -l <<< 'scale=2; '$temp'+.5')
        gtotal=$(echo $total)
        echo -e "$line" | awk -v orig="$temp" -v new="$gtotal" '{gsub(orig, new); print}' >> ./test1_mod.pdb
        count=$((count+1))
    else
        echo "$line" >> ./test1_mod.pdb
    fi
done
