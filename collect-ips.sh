#!/bin/bash

# Script to collect and combine IP addresses from multiple blocklists

set -euo pipefail

# Configuration
OUTPUT_IPV4="combined-blocklist-ipv4.txt"
OUTPUT_IPV6="combined-blocklist-ipv6.txt"
OUTPUT_ALL="combined-blocklist.txt"
TEMP_DIR=$(mktemp -d)

# URLs to fetch
URLS=(
    "https://raw.githubusercontent.com/borestad/blocklist-abuseipdb/refs/heads/main/abuseipdb-s100-7d.ipv4"
    "https://ipbl.herrbischoff.com/list.txt"
)

echo "Fetching IP blocklists..."

# Download all lists
for i in "${!URLS[@]}"; do
    echo "Downloading list $((i+1))/${#URLS[@]}: ${URLS[$i]}"
    curl -sS "${URLS[$i]}" > "${TEMP_DIR}/list_${i}.txt" || true
done

echo "Processing and combining IP addresses..."

# Extract IPv4 addresses
cat "${TEMP_DIR}"/list_*.txt | \
    grep -v '^#' | \
    grep -v '^$' | \
    grep -oE '\b([0-9]{1,3}\.){3}[0-9]{1,3}\b' | \
    sort -u -V > "${OUTPUT_IPV4}"

# Extract IPv6 addresses
cat "${TEMP_DIR}"/list_*.txt | \
    grep -v '^#' | \
    grep -v '^$' | \
    grep -oE '([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}' | \
    grep ':' | \
    sort -u > "${OUTPUT_IPV6}"

# Combine both IPv4 and IPv6
cat "${OUTPUT_IPV4}" "${OUTPUT_IPV6}" > "${OUTPUT_ALL}"

# Count results
TOTAL_IPV4=$(wc -l < "${OUTPUT_IPV4}")
TOTAL_IPV6=$(wc -l < "${OUTPUT_IPV6}")
TOTAL_ALL=$(wc -l < "${OUTPUT_ALL}")

# Cleanup
rm -rf "${TEMP_DIR}"

echo "Done!"
echo "  IPv4: ${TOTAL_IPV4} addresses -> ${OUTPUT_IPV4}"
echo "  IPv6: ${TOTAL_IPV6} addresses -> ${OUTPUT_IPV6}"
echo "  Total: ${TOTAL_ALL} addresses -> ${OUTPUT_ALL}"