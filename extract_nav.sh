#!/bin/bash

# AMFI NAV Data Extractor
# Extracts Scheme Name and Net Asset Value from AMFI India's NAV file
# Outputs in both TSV and JSON formats

set -euo pipefail

# Configuration
DATA_URL="https://www.amfiindia.com/spages/NAVAll.txt"
TSV_FILE="scheme_nav.tsv"
JSON_FILE="scheme_nav.json"
TEMP_FILE="NAVAll.txt"

# Cleanup function
cleanup() {
    rm -f "$TEMP_FILE"
}
trap cleanup EXIT

# Download the NAV data
echo "Downloading NAV data from AMFI..."
if ! curl -sSf "$DATA_URL" -o "$TEMP_FILE"; then
    echo "Error: Failed to download NAV data" >&2
    exit 1
fi

# Process TSV output
echo "Generating TSV file..."
awk -F ';' '
BEGIN { OFS="\t"; print "Scheme Name", "Net Asset Value" }
NF >= 5 && $4 != "" && $5 ~ /^[0-9.]+$/ { 
    gsub(/"/, "", $4);  # Remove quotes from scheme name
    print $4, $5 
}' "$TEMP_FILE" > "$TSV_FILE"

# Process JSON output
echo "Generating JSON file..."
awk -F ';' '
BEGIN { print "[" }
NF >= 5 && $4 != "" && $5 ~ /^[0-9.]+$/ { 
    gsub(/"/, "", $4);  # Remove quotes from scheme name
    if (NR > 1) print ","
    printf "  {\"scheme_name\": \"%s\", \"nav\": \"%s\"}", $4, $5
}
END { print "\n]" }' "$TEMP_FILE" > "$JSON_FILE"

echo "Successfully created:"
echo "- TSV output: $TSV_FILE"
echo "- JSON output: $JSON_FILE"