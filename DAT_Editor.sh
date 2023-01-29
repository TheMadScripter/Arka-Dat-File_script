#!/bin/bash

# Copies headers of file
head -n 1 ./test1.pdb > ./test1_mod.pdb

# Counter variable
count=0

# Asks users for questions to determine which column, value increase, decimal scale, beginning, and end line.
read -p "Which column would you like to manipulate? " col_var
read -p "What value would you like to increase by? " num_var
read -p "What decimal scale? 2 = x.x, 3 = x.xx, etc: " scale_var
read -p "From what line to begin with? " bline_var
read -p "Until what line? " uline_var

# Use awk to add 0.5 to the second field and print the modified line
tail -n +$bline_var ./test1.pdb | while read -r line; do
    # Only modify the first 48 lines
    if [ $count -lt $uline_var ]; then
        temp=$(echo $line | awk '{print $'$col_var'}')
        total=$(bc -l <<< 'scale='$scale_var'; '$temp'+'$num_var'')
        gtotal=$(echo $total)
        echo -e "$line" | awk -v orig="$temp" -v new="$gtotal" '{gsub(orig, new); print}' >> ./test1_mod.pdb
        count=$((count+1))
    else
        echo "$line" >> ./test1_mod.pdb
    fi
done
