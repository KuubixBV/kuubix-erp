#!/bin/bash

# Run the grep command and store the result in a variable
grep_output=$(grep -r '>executeHooks(' *)

# Extract the method names and sort them uniquely
unique_methods=$(echo "$grep_output" | awk -F"'" '{print $2}' | sort | uniq)

# Print the unique methods
echo -e "$unique_methods"
