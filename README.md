PVE-SecGroup

A robust, automated firewall object manager for Proxmox VE that dynamically aggregates ASN prefixes using bgpq4. This tool allows administrators to define security groups based on Autonomous System Numbers (ASNs) and automatically keeps them updated with the latest IP prefixes, optimized for performance.

Project URL: https://github.com/ENGINYRING/PVE-SecGroup

Author: ENGINYRING

📋 Table of Contents

Features

How It Works

Installation

Configuration

Usage

Automation

Example Output

Requirements

Disclaimer

License

🚀 Features

BGP Aggregation: Uses bgpq4 to fetch and merge thousands of /24 prefixes into optimized supernets (e.g., /19, /20), significantly reducing firewall rule count.

Atomic Updates: Performs updates using a "Working Configuration" approach. The live firewall is only touched once the new config is fully generated and validated.

Safety First: Automatically backs up the existing cluster firewall configuration before every run.

Multi-Group Support: Configure multiple security groups mapping to different ASNs (e.g., one group for "Trusted Partners" and another for "Blocked Bad Actors").

Modular Configuration: Logic is separated from configuration, allowing for easy updates and management.

Smart Detection: Automatically detects configuration files in local directories (for testing) or system directories (for production).

Verbose Logging: Detailed logs for auditing changes and troubleshooting.

🧠 How It Works

Fetch: The script queries the IRR (Internet Routing Registry) databases via bgpq4 for the specified ASNs.

Aggregate: It merges adjacent subnets. For example, instead of adding 256 individual rules for a /16 network, it adds a single rule.

Parse: It reads your /etc/pve/firewall/cluster.fw, identifies the target Security Group, and surgically replaces only that section.

Validate: It checks the integrity of the generated configuration.

Apply: It swaps the configuration and reloads the pve-firewall service.

💻 Installation

# 1. Install dependencies
apt-get update && apt-get install bgpq4

# 2. Clone the repository
git clone [https://github.com/ENGINYRING/PVE-SecGroup.git](https://github.com/ENGINYRING/PVE-SecGroup.git)

# 3. Change directory
cd PVE-SecGroup

# 4. Install script and config (Recommended location)
cp pve-secgroup.sh /usr/local/bin/
cp pve-secgroup.conf /etc/
chmod +x /usr/local/bin/pve-secgroup.sh


⚙️ Configuration

Edit the /etc/pve-secgroup.conf file to define your groups.

nano /etc/pve-secgroup.conf


Example Configuration:

# Rule Action: REJECT or DROP
RULE_ACTION="REJECT" 

# Define Groups
declare -A TARGET_GROUPS

# Format: TARGET_GROUPS["proxmox_group_name"]="ASN_LIST"

# Example 1: Block a specific ISP or Hosting Provider
TARGET_GROUPS["servers-tech-fzco"]="AS216071"

# Example 2: Allow a whitelist of trusted providers (Cloudflare & Google)
# TARGET_GROUPS["trusted-cdn"]="AS13335 AS15169"


🔧 Usage

You can run the script manually to test the update process. The script supports verbose output to standard out.

/usr/local/bin/pve-secgroup.sh


🤖 Automation

To keep your firewall rules up to date with BGP route changes, add a cron job. We recommend running this once daily.

crontab -e


Add the following line:

# Update Proxmox Firewall Groups daily at 02:00 AM
0 2 * * * /usr/local/bin/pve-secgroup.sh >/dev/null 2>&1


📝 Example Output

[2025-12-07 14:00:01] Starting Firewall Update Sequence...
[2025-12-07 14:00:01] Loaded configuration from: /etc/pve-secgroup.conf
[2025-12-07 14:00:01] Backup created at /etc/pve/firewall/backups/cluster.fw.1733572801.bak
[2025-12-07 14:00:02] Processing Group: [servers-tech-fzco] | ASNs: AS216071
[2025-12-07 14:00:03]   -> Fetched 42 aggregated prefixes.
[2025-12-07 14:00:03]   -> Group [servers-tech-fzco] updated in working config.
[2025-12-07 14:00:03] All groups processed. Configuration applied to /etc/pve/firewall/cluster.fw
[2025-12-07 14:00:04] Firewall service restarted successfully
[2025-12-07 14:00:04] Update sequence completed.


📦 Requirements

OS: Proxmox VE (Debian-based)

Dependencies: bgpq4

Access: Root privileges are required to modify firewall configurations.

⚠️ Disclaimer

IMPORTANT: This tool is provided "as is" without warranties or guarantees of any kind, express or implied.

ENGINYRING is NOT RESPONSIBLE for any connectivity loss, system instability, or data loss arising from the use of this tool.

Incorrect ASN configurations can lead to locking yourself out of your server. Always ensure you have out-of-band access (IPMI/KVM) or a whitelist for your management IP.

Always TEST CONFIGURATIONS in a non-production environment first.

By using this tool, you acknowledge that you are making automated changes to your firewall security policies AT YOUR OWN RISK.

ALWAYS BACKUP your original configuration before applying any changes.

📄 License

This project is licensed under the MIT License - see the LICENSE file in the repository for details.

MIT License

Copyright (c) 2025 ENGINYRING

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.


<p align="center">
<a href="https://www.enginyring.com">
<img src="https://img.shields.io/badge/Powered%20by-ENGINYRING-blue" alt="Powered by ENGINYRING">
</a>





High-Performance Web Hosting & VPS Services
</p>

© 2025 ENGINYRING. All rights reserved.

Web hosting | VPS hosting | Free DevOps tools
