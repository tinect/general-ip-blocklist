#!/bin/sh

# Script to collect and combine IP addresses from multiple blocklists
# POSIX sh compatible

set -eu

# Configuration
OUTPUT_IPV4="combined-blocklist-ipv4.txt"
OUTPUT_IPV6="combined-blocklist-ipv6.txt"
OUTPUT_ALL="combined-blocklist.txt"
TEMP_DIR=$(mktemp -d)

# URLs to fetch (space-separated)
URL_1="https://raw.githubusercontent.com/borestad/blocklist-abuseipdb/refs/heads/main/abuseipdb-s100-7d.ipv4"
URL_2="https://ipbl.herrbischoff.com/list.txt"

echo "Fetching IP blocklists..."

# Download all lists
i=1
for url in "$URL_1" "$URL_2"; do
    echo "Downloading list ${i}/2: ${url}"
    curl -sS "${url}" > "${TEMP_DIR}/list_${i}.txt" || true
    i=$((i + 1))
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

# Verify that output files are not empty
if [ "${TOTAL_ALL}" -eq 0 ]; then
    echo "Error: Combined output file is empty - no IP addresses found"
    exit 1
fi

if [ "${TOTAL_IPV4}" -eq 0 ]; then
    echo "Error: IPv4 output file is empty - no IPv4 addresses found"
    exit 1
fi

echo "Done!"
echo "  IPv4: ${TOTAL_IPV4} addresses -> ${OUTPUT_IPV4}"
echo "  IPv6: ${TOTAL_IPV6} addresses -> ${OUTPUT_IPV6}"
echo "  Total: ${TOTAL_ALL} addresses -> ${OUTPUT_ALL}"