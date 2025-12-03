#!/bin/sh

# Script to collect and combine IP addresses from multiple blocklists
# POSIX sh compatible

set -eu

# Configuration
OUTPUT_IPV4="combined-blocklist-ipv4.txt"
OUTPUT_IPV6="combined-blocklist-ipv6.txt"
OUTPUT_ALL="combined-blocklist.txt"
OUTPUT_IPV4_AGG="combined-blocklist-ipv4-aggregated.txt"
TEMP_DIR=$(mktemp -d)

# URLs to fetch (space-separated)
URL_1="https://raw.githubusercontent.com/borestad/blocklist-abuseipdb/refs/heads/main/abuseipdb-s100-7d.ipv4"
URL_2="https://ipbl.herrbischoff.com/list.txt"
URL_3="https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/botscout_7d.ipset"
URL_4="https://blocklist.greensnow.co/greensnow.txt"
URL_5="https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/cybercrime.ipset"
URL_6="https://lists.blocklist.de/lists/ssh.txt"
URL_7="https://lists.blocklist.de/lists/strongips.txt"
URL_8="https://lists.blocklist.de/lists/bruteforcelogin.txt"

echo "Fetching IP blocklists..."

# Download all lists
i=1
successful_downloads=0
total_lists=8
for url in "$URL_1" "$URL_2" "$URL_3" "$URL_4" "$URL_5" "$URL_6" "$URL_7" "$URL_8"; do
    echo "Downloading list ${i}/${total_lists}: ${url}"

    # Download the list
    if curl -sS "${url}" > "${TEMP_DIR}/list_${i}.txt"; then
        # Check if file has content
        if [ -s "${TEMP_DIR}/list_${i}.txt" ]; then
            # Check if file contains at least one IP address
            if grep -qoE '([0-9]{1,3}\.){3}[0-9]{1,3}|([0-9a-fA-F]{0,4}:){2,7}[0-9a-fA-F]{0,4}' "${TEMP_DIR}/list_${i}.txt"; then
                echo "  ✓ Downloaded and validated"
                successful_downloads=$((successful_downloads + 1))
            else
                echo "  ⚠ Warning: File downloaded but contains no IP addresses"
            fi
        else
            echo "  ⚠ Warning: Downloaded file is empty"
        fi
    else
        echo "  ✗ Error: Failed to download"
        # Create empty file to prevent errors in later processing
        touch "${TEMP_DIR}/list_${i}.txt"
    fi

    i=$((i + 1))
done

echo ""
echo "Download summary: ${successful_downloads}/${total_lists} lists successfully downloaded"

if [ "${successful_downloads}" -ne "${total_lists}" ]; then
    echo "Error: Not all blocklists were successfully downloaded"
    exit 1
fi

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

echo "Aggregating IP addresses into CIDR blocks..."

# Aggregate IPv4 addresses (requires 'aggregate' tool)
TOTAL_IPV4_AGG=0
if command -v aggregate >/dev/null 2>&1; then
    aggregate -p 32 -t < "${OUTPUT_IPV4}" > "${OUTPUT_IPV4_AGG}"
    TOTAL_IPV4_AGG=$(wc -l < "${OUTPUT_IPV4_AGG}")
    echo "  IPv4 aggregated: ${TOTAL_IPV4} -> ${TOTAL_IPV4_AGG} CIDR blocks"
else
    echo "  Warning: 'aggregate' tool not found, skipping IPv4 aggregation"
fi

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
echo ""
echo "Non-aggregated lists:"
echo "  IPv4: ${TOTAL_IPV4} addresses -> ${OUTPUT_IPV4}"
echo "  IPv6: ${TOTAL_IPV6} addresses -> ${OUTPUT_IPV6}"
echo "  Total: ${TOTAL_ALL} addresses -> ${OUTPUT_ALL}"
echo ""
echo "Aggregated lists (CIDR blocks):"
echo "  IPv4: ${TOTAL_IPV4_AGG} blocks -> ${OUTPUT_IPV4_AGG}"