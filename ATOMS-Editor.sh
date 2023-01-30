#!/bin/bash

# Copies from the top of the file to Atoms
topvar=$(head -n 1 ./data.lmp)
sed -n '/'"$topvar"'/,/^Atoms/p' ./data.lmp > ./data_mod.lmp

# Adds a single blank line to keep in line with all other formatting.
echo "" >> ././data_mod.lmp

# Copies all Atoms info to a temp file for data modification.
sed -n '/^Atoms/,/^[A-Za-z]/p' ./data.lmp > ./temp_data.txt

# Deletes the the copied over Atoms header and the last line in file. This is to not interfere with data manipulation.
sed -i '1d' ./temp_data.txt
sed -i '$d' ./temp_data.txt
sed -i '/^$/d' ./temp_data.txt

# Asks users for questions to determine which column to edit and what value to increase by.
read -p "Which column would you like to manipulate? " col_var
read -p "What value would you like to increase by? " num_var
read -p "From what line to begin with? " bline_var
read -p "Until what line? " uline_var

# Counter
count=0

# Use awk to add the desired amount to the requested column
tail -n +$bline_var ./temp_data.txt | while read -r line; do
    if [ $count -lt $uline_var ]; then
    
        # Identifies which column to use
        temp=$(echo $line | awk '{print $'$col_var'}')
        
        # Converts the scientific notation to decimal
        sctodec=$(echo "$temp" | awk '{printf "%.10f", $1}')
        
        # Adds the new decimal form number with the requested amount
        addvar=$(echo "$sctodec+$num_var" | bc)
        
        # Converts the decimal back into scientific notation.
        dectosc=$(printf "%.6e\n" $addvar)
        #finalsc=$(echo $dectosc)
        
        # Changes out the old number with new total.
        echo -e "$line" | sed 's/'"$temp"'/'"$dectosc"'/p' | sort -u >> ./data_mod.lmp
        
        count=$((count+1))
    else
        echo "$line" >> ./data_mod.lmp
    fi    
done

# Copies everything after Bonds to the new file and adds a blank line above bonds.
echo "" >> ./data_mod.lmp
sed -n '/^Bonds/,/*/p' ./data.lmp  >> ./data_mod.lmp
