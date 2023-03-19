#!/bin/bash

#### Folder Creation

  echo "Checking Folder Structure."

  # TEMP folder will be used to house files for editing
  dirs=(./TEMP ./TEMP/BLOB ./TEMPLATE ./FINAL)

  for dir in "${dirs[@]}"; do
    if [ ! -d "$dir" ]; then
      mkdir "$dir"
    fi
  done

#### Variables

  # Sets color for text
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  NC='\033[0m'

  echo "Creating Variables."

  # Asks which file the user wants to use
  echo -e "${GREEN}1. charge.xvg\n2. field.xvg\n3. pot_out.xvg\n4. out.xvg\n${NC}"
  read -p "Which file type would you like to use? Enter number to select: " choice_var
  
  if [ "$choice_var" == "1" ]; then
    fname="charge"
  elif [ "$choice_var" == "2" ]; then
    fname="field"
  elif [ "$choice_var" == "3" ]; then
    fname="pot_out"
  elif [ "$choice_var" == "4" ]; then
    fname="out"
  fi
    
  # Finds all files in folders that are named as numbers.
  cfg=$(find ./ -type d -not -path '\/.*' -regextype posix-egrep -regex '^.*/([1-9]|[1-9][0-9]{1,3})$' -printf '%f\n')
  
  # Counts the amount of .xvg files in TEMP. Used to find average.
  f_count=$(ls ./TEMP | grep -c .xvg)

#### Cleanup

  echo "Performing cleanup."

  # Cleans up the folders to ensure nothing residual is left to cause any conflicts.
  rm -f ./TEMP/*{,BLOB/*} ./TEMPLATE/* ./FINAL/* > /dev/null 2>&1

#### Prep

  echo "Preparing items."

  cnt=0
  
  # Goes through all folders and copies the contents into the TEMP folder.
  for c in $cfg
  do
    
    # Goes through and copies all the information for the columns into their own unique file name
    sed -n '/^@ s1 legend/,/*/p' $c/$fname.xvg > ./TEMP/"file_"$cnt".xvg"
    
    # Deletes header and line right below it to only have the values
    sed -i '1d' ./TEMP/"file_"$cnt".xvg"
    
    # Increments the count by 1, used for file naming.
    cnt=$((cnt+1))
  
  done
  
#### Final File Preperation

  echo "Preparing final steps before execution."
  
  # Copies one of the original files information to a final file destination.
  cp "$(find ./ -type f -path '*/[0-9]*' -name "*$fname.xvg" -print0 | shuf -zn1 -z)" ./TEMPLATE
  
  topvar=$(head -n 1 ./TEMPLATE/*)
  sed -n '/'"$topvar"'/,/^@ s1 legend/p' ./TEMPLATE/* > ./FINAL/""$fname".xvg"
  
  echo "Prepeartion is done. Commencing main script execution!"
  
#### Main Script Execution  

  echo "Creating temp files"

  # specify the number of rows and columns in the files
  num_rows=$(grep -c '.*' ./TEMP/file_0.xvg | awk '{print $1}')
  num_cols=$(awk -F' ' '{print NF; exit}' ./TEMP/file_0.xvg)

  # create new files for each combination of row and column
  for ((row=1; row<=$num_rows; row++)); do
    for ((col=1; col<=$num_cols; col++)); do
      touch "./TEMP/BLOB/row${row}_col${col}.txt"
    done
  done

  # loop through each file and extract the relevant data to the appropriate file
  for file in ./TEMP/*.xvg; do
    for ((row=1; row<=$num_rows; row++)); do
      for ((col=1; col<=$num_cols; col++)); do
        awk -v row="$row" -v col="$col" 'NR==row{print $col}' "$file" >> ./TEMP/BLOB/"row${row}_col${col}.txt"
      done
    done
  done

  echo "Doing conversions"

  # Goes through and finds average
  dfg=./TEMP/BLOB/row*[1-3].txt
  
  for d in $dfg
  do
  
    # Code to create a variable of the file it is pulling from to create a temp file to do math.
    output_file="${d%.*}_temp"
    
    > $output_file
  
    # Reads through each line of each file to check what type of data is in there.
    cat $d | while read -r line; do
      temp=$(echo $line)
      
      # IF statement for scientific notations.
      if echo $line | grep -i [a-z] > /dev/null 2>&1; then
        # Converts the scientific notation to decimal and sends to temp file
        echo "$temp" | awk '{printf "%.10f\n", $1}' >> $output_file
      else
        echo $temp >> $output_file
      fi
    done
    
    # Goes through temp file, adds numbers, and finds average. Then sends back to original file.
    input_file="$output_file"
    
    sum=$(awk '{ total += $1 } END { printf "%.10f\n", total }' $input_file)
    
    # print the total sum and finds average by dividing by .xvg file count.
    temp_total=$(echo $sum)
    final_sum=$(echo "$temp_total / $f_count" | bc -l)
    echo $final_sum > $d
    
  done        

#### Data Finalization

  echo "Finalization process"

  # specify the number of rows and columns in the files
  num_rows=$(grep -c '.*' ./TEMP/file_0.xvg | awk '{print $1}')
  num_cols=$(awk -F' ' '{print NF; exit}' ./TEMP/file_0.xvg)
  
  # create a new file to hold the combined data.
  > ./TEMP/combined.txt
  
  # initialize an array to store the values for each row
  declare -a row_values
  
  # loop through each row and concatenate the values from the corresponding files horizontally
  for ((row=1; row<=$num_rows; row++)); do
    # clear the row values array
    row_values=()
    
    # concatenate the values from each file for this row
    for ((col=1; col<=$num_cols; col++)); do
      # read the value from the file into a variable
      read -r value < "./TEMP/BLOB/row${row}_col${col}.txt"
      
      # add the value to the row values array
      row_values+=("$value")
    done
    
    # concatenate the row values into a single line with tabs
    row_line=$(printf '%s\t' "${row_values[@]}")
    
    # remove the trailing tab and add a newline character
    row_line=${row_line%$'\t'}
    echo "$row_line" >> ./TEMP/combined.txt
  done


#### Formatting
  input_file="./TEMP/combined.txt"
  
  # Set the desired GROMACS column spacing (default is 10 spaces)
  gmx_spacing=10
  
  # Calculate the maximum column width in the input file
  max_width=$(awk '{ for (i=1;i<=NF;i++) { w=length($i); if (w>x) x=w; } } END { print x+1 }' "$input_file")
  
  # Calculate the number of spaces needed to conform to GROMACS spacing
  spaces_needed=$(( gmx_spacing - max_width ))
  
  # Add the necessary spaces to each column in the input file
  awk -v pad="$spaces_needed" '{ for (i=1;i<=NF;i++) printf "%25s", $i; printf "\n" }' "$input_file" >> ./FINAL/""$fname".xvg"
