#!/bin/bash

# # Make sure to set the variables when calling the script
# Example:
# ./concatenate_sberry_assembly_stats_report.sh --parent_directory "/path/to/parent" --output_filename "output.tsv" --output_dir "/path/to/output"

# Default values
parent_directory=""
output_filename=""
output_dir=""

# Function to display usage instructions
usage() {
    echo "Usage: $0 [--parent_directory <directory>] [--output_filename <filename>] [--output_dir <directory>]"
    exit 1
}

# Parse command-line arguments
while [ "$#" -gt 0 ]; do
    case "$1" in
        --parent_directory)
            parent_directory="$2"
            shift 2
            ;;
        --output_filename)
            output_filename="$2"
            shift 2
            ;;
        --output_dir)
            output_dir="$2"
            shift 2
            ;;
        *)
            usage
            ;;
    esac
done

# Check if required arguments are provided
if [ -z "$parent_directory" ] || [ -z "$output_filename" ] || [ -z "$output_dir" ]; then
    usage
fi

# Full path to the output file
output_file="$output_dir/$output_filename"

# Rest of the script remains the same
# Check if the output file already exists, and if so, remove it
if [ -e "$output_file" ]; then
    rm "$output_file"
fi

# Find the first ".report.tsv" file to get the header
first_report_file=""
for subdir in "$parent_directory"/*; do
    if [ -d "$subdir" ]; then
        first_report_file=$(find "$subdir" -name "*.report.tsv" -print -quit)
        if [ -n "$first_report_file" ]; then
            break
        fi
    fi
done

# Check if the first report file was found
if [ -z "$first_report_file" ]; then
    echo "No '.report.tsv' files found in subdirectories."
    exit 1
fi

# Extract the header from the first report file
header=$(head -n 1 "$first_report_file")

# Write the header to the output file
#echo -e "Directory\t$header" > "$output_file"
echo -e "Directory\tref_id\tseq_num\tref_size\tasm_size\tN50\tunaligned_ref\tunaligned_asm\tANI\tdup_ratio\tdup_bases\tcmp_bases\tsnps\tinversions\trelocations\ttransloc" > "$output_file"

# Loop through subdirectories and concatenate data from '.report.tsv' files
for subdir in "$parent_directory"/*; do
    if [ -d "$subdir" ]; then
        dir_name=$(basename "$subdir")
        report_file=$(find "$subdir" -name "*.report.tsv")

        if [ -n "$report_file" ]; then
            # Extract directory name without underscores
           # dir_name_no_underscore=$(echo "$dir_name" | tr -d "_")

            # Append data lines with directory name to the output file
            awk -v dir="$dir_name" 'NR > 1 {print dir "\t" $0}' "$report_file" >> "$output_file"
        fi
    fi
done

echo "Concatenation complete. Data saved in $output_file."
