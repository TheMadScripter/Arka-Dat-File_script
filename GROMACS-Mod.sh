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
  sed -n '/'"$topvar"'/,/^@ s1 legend/p' ./TEMPLATE/* > ./FINAL/final.xvg
  
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

