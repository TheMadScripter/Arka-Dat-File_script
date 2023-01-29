#!/bin/bash

# Copies header to final file
head -n 1 ./test1.pdb > ./test1_mod.pdb

# Counter Variable
count=0

> ./temp_file.txt

# Copies lines 2 through 49 to temp file
tail -n +2 ./test1.pdb | while read -r line; do
        # Only modify the first 48 lines
        if [ $count -lt 48 ]; then
                echo "$line" >> ./temp_file.txt
                count=$((count+1))
        fi
done

# makes changes to second column number
cat ./temp_file.txt | while read -r line; do
        temp=$(echo $line | awk '{print $2}')
        total=$(bc -l <<< 'scale=2; '$temp'+.5')
        gtotal=$(echo $total)
        echo -e "$line" | awk -v orig="$temp" -v new="$gtotal" '{gsub(orig, new); print}' >> ./test1_mod.pdb
done

#copies rest of data from line 50 to new file
tail -n +50 ./test1.pdb >> ./test1_mod.pdb
