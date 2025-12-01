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

3. **Botscout 7d** - IPs from bot/spam activity in the last 7 days (FireHOL)
   - `https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/botscout_7d.ipset`

4. **GreenSnow** - Malicious IPs tracked by GreenSnow (FireHOL)
   - `https://raw.githubusercontent.com/firehol/blocklist-ipsets/refs/heads/master/greensnow.ipset`

## Requirements

- POSIX-compliant shell (`sh`, `bash`, `dash`, etc.)
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
Downloading list 1/4: https://raw.githubusercontent.com/borestad/blocklist-abuseipdb/...
Downloading list 2/4: https://ipbl.herrbischoff.com/list.txt
Downloading list 3/4: https://raw.githubusercontent.com/firehol/blocklist-ipsets/...botscout_7d.ipset
Downloading list 4/4: https://raw.githubusercontent.com/firehol/blocklist-ipsets/...greensnow.ipset
Processing and combining IP addresses...
Done!
  IPv4: 72130 addresses -> combined-blocklist-ipv4.txt
  IPv6: 288 addresses -> combined-blocklist-ipv6.txt
  Total: 72418 addresses -> combined-blocklist.txt
```

## Features

- **POSIX-compliant**: Works with any POSIX shell (sh, bash, dash, etc.)
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
- **CrowdSec integration** (automated import into CrowdSec decisions)

## CrowdSec Integration

The `import-to-crowdsec.sh` script automatically downloads the blocklist and imports it into CrowdSec decisions, blocking malicious IPs at the system level.

### Requirements

- CrowdSec installed (local or Docker)
- `cscli` command-line tool (included with CrowdSec)
- `curl` for downloading blocklists

### Configuration

Create a `.env` file (optional) to customize the import behavior:

```bash
cp .env.example .env
```

Available configuration options:

- **`BAN_DURATION`**: How long IPs should be banned (default: `24h`)
  - Examples: `1h`, `12h`, `24h`, `7d`, `30d`
- **`BAN_REASON`**: Reason displayed in CrowdSec (default: `general-ip-blocklist`)
- **`CROWDSEC_DOCKER_CONTAINER`**: Docker container name if CrowdSec runs in Docker (leave empty for local installation)

### Usage

```
curl -o import-to-crowdsec.sh https://raw.githubusercontent.com/tinect/general-ip-blocklist/refs/heads/main/import-to-crowdsec.sh
chmod +x import-to-crowdsec.sh
```

#### Local CrowdSec Installation

```bash
./import-to-crowdsec.sh
```

#### Docker Installation

Set the container name and run:

```bash
export CROWDSEC_DOCKER_CONTAINER=crowdsec
./import-to-crowdsec.sh
```

Or use the `.env` file:

```bash
# In .env file
CROWDSEC_DOCKER_CONTAINER=crowdsec
```

```bash
source .env && ./import-to-crowdsec.sh
```

### Viewing Imported Decisions

**Local installation:**
```bash
cscli decisions list --origin cscli-import
```

**Docker installation:**
```bash
docker exec crowdsec cscli decisions list --origin cscli-import
```

### Automated Import with Cron

To keep your CrowdSec decisions up-to-date, schedule the import script:

**Option 1: Using local script**
```bash
# Edit crontab
crontab -e

# Add this line to run daily at 3 AM
0 3 * * * /bin/sh /path/to/unwanted-ip-addresses/import-to-crowdsec.sh >> /var/log/crowdsec-import.log 2>&1
```

**Option 2: Using one-liner (always downloads latest version)**
```bash
# Edit crontab
crontab -e

# For local CrowdSec
0 3 * * * curl -fsSL https://raw.githubusercontent.com/tinect/general-ip-blocklist/refs/heads/main/import-to-crowdsec.sh | sh >> /var/log/crowdsec-import.log 2>&1

# For Docker CrowdSec
0 3 * * * curl -fsSL https://raw.githubusercontent.com/tinect/general-ip-blocklist/refs/heads/main/import-to-crowdsec.sh | CROWDSEC_DOCKER_CONTAINER=crowdsec sh >> /var/log/crowdsec-import.log 2>&1
```

### How It Works

1. Downloads the latest `combined-blocklist.txt` from this repository
2. Converts IP addresses to CrowdSec CSV decision format
3. Imports decisions using `cscli decisions import`
4. Automatically handles both local and Docker CrowdSec installations

### Troubleshooting

**"cscli command not found"**
- Ensure CrowdSec is installed or set `CROWDSEC_DOCKER_CONTAINER`

**"Docker container not running"**
- Verify the container name: `docker ps`
- Update `CROWDSEC_DOCKER_CONTAINER` with the correct name

**"Failed to import decisions"**
- Check CrowdSec is running: `systemctl status crowdsec` (local) or `docker ps` (Docker)
- Verify you have appropriate permissions to run `cscli`

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