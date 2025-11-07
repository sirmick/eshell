#!/bin/bash
# For and While Loops Example

# Basic for loop
echo "### For Loop Basic"
for file in *.txt
do
    echo "Processing $file"
done

# For loop with file globbing
echo "### For Loop with Globbing"
for image in *.jpg *.png *.gif
do
    echo "Converting $image"
done

# For loop with numbers (C-style)
echo "### For Loop Numbers"
for i in 1 2 3 4 5
do
    echo "Number: $i"
done

# While loop with file test
echo "### While Loop with File Test"
while test -f watchfile.txt
do
    echo "File exists at $(date)"
    sleep 5
done

# While loop with variable check
echo "### While Loop Counter"
counter=0
while test $counter -lt 10
do
    echo "Counter: $counter"
    counter=$((counter + 1))
done

# While loop with multiple conditions
echo "### While Loop Multiple Conditions"
line_count=0
while test $line_count -lt 10 && test -f input.txt
do
    echo "Processing line $line_count"
    line_count=$((line_count + 1))
done

# For loop with command substitution
echo "### For Loop Command Substitution"
for process in $(ps aux | grep bash | awk '{print $2}')
do
    echo "Processing PID: $process"
done

# Nested loops
echo "### Nested Loops"
for dir in subdir*
do
    if test -d "$dir"; then
        for file in "$dir"/*.txt
        do
            echo "Found $file in $dir"
        done
    fi
done

# Loop with break/continue
echo "### Loop with Break/Continue"
for num in 1 2 3 4 5 6 7 8 9 10
do
    if test $num -eq 5; then
        continue
    fi
    if test $num -eq 8; then
        break
    fi
    echo "Number: $num"
done

# Interactive while loop
echo "### Interactive While Loop"
echo "Enter 'quit' to exit:"
while true
do
    read -p "> " input
    if test "$input" = "quit"; then
        break
    fi
    echo "You entered: $input"
done