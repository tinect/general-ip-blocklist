# Unwanted IP Addresses Blocklist

A bash script to fetch, combine, and deduplicate IP addresses from multiple threat intelligence blocklists.

## Overview

This tool downloads IP addresses from reputable blocklist sources and combines them into unified lists, making it easy to block malicious traffic in firewalls, web servers, or other security tools.

## Sources

The script fetches IP addresses from the following sources:

1. **AbuseIPDB** - IPv4 addresses with 100% confidence score from the last 7 days
   - `https://raw.githubusercontent.com/borestad/blocklist-abuseipdb/refs/heads/main/abuseipdb-s100-7d.ipv4`

2. **Herrbischoff IP Blocklist** - Curated list of malicious IP addresses (IPv4 and IPv6)
   - `https://ipbl.herrbischoff.com/list.txt`

## Requirements

- `bash` (4.0 or later)
- `curl`
- `grep`
- Standard Unix utilities (`sort`, `cat`, `wc`)

## Usage

### Basic Usage

```bash
./collect-ips.sh
```

### Output Files

The script generates three files:

1. **`combined-blocklist-ipv4.txt`** - All unique IPv4 addresses
2. **`combined-blocklist-ipv6.txt`** - All unique IPv6 addresses
3. **`combined-blocklist.txt`** - Combined list of all IP addresses

### Example Output

```
Fetching IP blocklists...
Downloading list 1/2: https://raw.githubusercontent.com/borestad/blocklist-abuseipdb/...
Downloading list 2/2: https://ipbl.herrbischoff.com/list.txt
Processing and combining IP addresses...
Done!
  IPv4: 72130 addresses -> combined-blocklist-ipv4.txt
  IPv6: 288 addresses -> combined-blocklist-ipv6.txt
  Total: 72418 addresses -> combined-blocklist.txt
```

## Features

- **Automatic deduplication**: All IP addresses are unique
- **Multi-source aggregation**: Combines multiple trusted sources
- **Separate IPv4/IPv6 lists**: Choose the format you need
- **Comment removal**: Filters out comments and empty lines
- **Sorted output**: IP addresses are sorted for easy searching

## Use Cases

- Firewall rules (iptables, nftables, pfSense, etc.)
- Web server configuration (nginx, Apache)
- Intrusion detection/prevention systems
- Network monitoring tools
- Application-level IP blocking

## Automatic Updates

This repository includes a GitHub Actions workflow that automatically updates the blocklist files every 2 hours.

### How It Works

- Runs on schedule: Every 2 hours via cron (`0 */2 * * *`)
- Can be manually triggered via GitHub Actions UI
- Only commits changes if the blocklists have been updated
- Uses GitHub Actions bot for commits

### Manual Trigger

You can manually trigger the workflow from the GitHub repository:
1. Go to the "Actions" tab
2. Select "Update IP Blocklists"
3. Click "Run workflow"

## License

This project aggregates publicly available blocklists. Please refer to the original sources for their respective licenses and usage terms.

## Contributing

Feel free to submit issues or pull requests to add more blocklist sources or improve the script.

## Disclaimer

These blocklists are provided as-is. Always test in a non-production environment before deploying to production systems. False positives may occur.