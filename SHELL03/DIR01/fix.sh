#!/bin/bash

# Loop through each file with the pattern "T1d*.png"
for file in T2d*.png; do
    # Extract the base part (e.g., T1d) and the number (e.g., 08125) without extension
    base="${file%%d*}d"
    num="${file##*d}"
    num="${num%.png}"
    
    # Pad the decimal part with zeros to ensure it has 8 digits
    padded_num=$(printf "%-8s" "$num" | tr ' ' '0')
    
    # Create the new filename with padded decimal part
    new_filename="${base}${padded_num}.png"
    
    # Rename the file
    mv "$file" "$new_filename"
    echo "Renamed $file to $new_filename"
done
