<div align="center">
  <a href="https://www.enginyring.com">
    <img src="https://cdn.enginyring.com/img/logo_dark.png" alt="ENGINYRING" width="200">
  </a>
</div>

<h1 align="center">PVE-SecGroup</h1>

<p align="center">
  <img src="https://img.shields.io/badge/PVE--SecGroup-v1.0.0-blue" alt="PVE-SecGroup Banner">
  <img src="https://img.shields.io/badge/license-MIT-green" alt="License">
</p>

<p align="center">
  A robust, automated firewall object manager for Proxmox VE that dynamically aggregates ASN prefixes using <code>bgpq4</code>. This tool allows administrators to define security groups based on Autonomous System Numbers (ASNs) and automatically keeps them updated with the latest IP prefixes, optimized for performance.
</p>

<p align="center">
  <strong>Project URL</strong>: <a href="https://github.com/ENGINYRING/PVE-SecGroup">https://github.com/ENGINYRING/PVE-SecGroup</a><br>
  <strong>Author</strong>: <a href="https://www.enginyring.com">ENGINYRING</a>
</p>

<hr>

<h2>📋 Table of Contents</h2>

<ul>
  <li><a href="#features">Features</a></li>
  <li><a href="#installation">Installation</a></li>
  <li><a href="#usage">Usage</a></li>
  <li><a href="#configuration">Configuration</a></li>
  <li><a href="#automation">Automation</a></li>
  <li><a href="#example-output">Example Output</a></li>
  <li><a href="#requirements">Requirements</a></li>
  <li><a href="#disclaimer">Disclaimer</a></li>
  <li><a href="#license">License</a></li>
</ul>

<h2 id="features">🚀 Features</h2>

<ul>
  <li><strong>BGP Aggregation</strong>: Uses <code>bgpq4</code> to fetch and merge thousands of /24 prefixes into optimized supernets (e.g., /19, /20), significantly reducing firewall rule count.</li>
  <li><strong>Atomic Updates</strong>: Performs updates using a "Working Configuration" approach. The live firewall is only touched once the new config is fully generated and validated.</li>
  <li><strong>Safety First</strong>: Automatically backs up the existing cluster firewall configuration before every run.</li>
  <li><strong>Multi-Group Support</strong>: Configure multiple security groups mapping to different ASNs (e.g., one group for "Trusted Partners" and another for "Blocked Bad Actors").</li>
  <li><strong>Modular Configuration</strong>: Logic is separated from configuration, allowing for easy updates and management.</li>
  <li><strong>Smart Detection</strong>: Automatically detects configuration files in local directories (for testing) or system directories (for production).</li>
  <li><strong>Verbose Logging</strong>: Detailed logs for auditing changes and troubleshooting.</li>
</ul>

<h2 id="installation">💻 Installation</h2>

<pre><code># 1. Install dependencies
apt-get update && apt-get install bgpq4

# 2. Clone the repository
git clone https://github.com/ENGINYRING/PVE-SecGroup.git

# 3. Change directory
cd PVE-SecGroup

# 4. Install script and config (Recommended location)
cp pve-secgroup.sh /usr/local/bin/
cp pve-secgroup.conf /etc/
chmod +x /usr/local/bin/pve-secgroup.sh
</code></pre>

<h2 id="usage">🔧 Usage</h2>

<p>You can run the script manually to test the update process. The script supports verbose output to standard out.</p>

<pre><code>/usr/local/bin/pve-secgroup.sh
</code></pre>

<h2 id="configuration">⚙️ Configuration</h2>

<p>Edit the <code>/etc/pve-secgroup.conf</code> file to define your groups.</p>

<pre><code>nano /etc/pve-secgroup.conf
</code></pre>

<p><strong>Example Configuration:</strong></p>

<pre><code># Rule Action: REJECT or DROP
RULE_ACTION="REJECT" 

# Define Groups
declare -A TARGET_GROUPS

# Format: TARGET_GROUPS["proxmox_group_name"]="ASN_LIST"

# Example 1: Block a specific ISP or Hosting Provider
TARGET_GROUPS["servers-tech-fzco"]="AS216071"

# Example 2: Allow a whitelist of trusted providers (Cloudflare & Google)
# TARGET_GROUPS["trusted-cdn"]="AS13335 AS15169"
</code></pre>

<h2 id="automation">🤖 Automation</h2>

<p>To keep your firewall rules up to date with BGP route changes, add a cron job. We recommend running this once daily.</p>

<pre><code>crontab -e
</code></pre>

<p>Add the following line:</p>

<pre><code># Update Proxmox Firewall Groups daily at 02:00 AM
0 2 * * * /usr/local/bin/pve-secgroup.sh >/dev/null 2>&1
</code></pre>

<h2 id="example-output">📝 Example Output</h2>

<p>The script provides clear feedback on every step of the process:</p>

<pre><code>[2025-12-07 14:00:01] Starting Firewall Update Sequence...
[2025-12-07 14:00:01] Loaded configuration from: /etc/pve-secgroup.conf
[2025-12-07 14:00:01] Backup created at /etc/pve/firewall/backups/cluster.fw.1733572801.bak
[2025-12-07 14:00:02] Processing Group: [servers-tech-fzco] | ASNs: AS216071
[2025-12-07 14:00:03]   -> Fetched 42 aggregated prefixes.
[2025-12-07 14:00:03]   -> Group [servers-tech-fzco] updated in working config.
[2025-12-07 14:00:03] All groups processed. Configuration applied to /etc/pve/firewall/cluster.fw
[2025-12-07 14:00:04] Firewall service restarted successfully
[2025-12-07 14:00:04] Update sequence completed.
</code></pre>

<h2 id="requirements">📦 Requirements</h2>

<ul>
  <li><strong>OS</strong>: Proxmox VE (Debian-based)</li>
  <li><strong>Dependencies</strong>: <code>bgpq4</code></li>
  <li><strong>Access</strong>: Root privileges are required to modify firewall configurations.</li>
</ul>

<h2 id="disclaimer">⚠️ Disclaimer</h2>

<p><strong>IMPORTANT</strong>: This tool is provided "as is" without warranties or guarantees of any kind, express or implied.</p>

<ul>
  <li>ENGINYRING is <strong>NOT RESPONSIBLE</strong> for any connectivity loss, system instability, or data loss arising from the use of this tool.</li>
  <li>Incorrect ASN configurations can lead to locking yourself out of your server. Always ensure you have out-of-band access (IPMI/KVM) or a whitelist for your management IP.</li>
  <li>Always <strong>TEST CONFIGURATIONS</strong> in a non-production environment first.</li>
  <li>By using this tool, you acknowledge that you are making automated changes to your firewall security policies <strong>AT YOUR OWN RISK</strong>.</li>
  <li><strong>ALWAYS BACKUP</strong> your original configuration before applying any changes.</li>
</ul>

<h2 id="license">📄 License</h2>

<p>This project is licensed under the MIT License - see the LICENSE file in the repository for details.</p>

<pre><code>MIT License

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
</code></pre>

<hr>

<p align="center">
  <a href="https://www.enginyring.com">
    <img src="https://img.shields.io/badge/Powered%20by-ENGINYRING-blue" alt="Powered by ENGINYRING">
  </a>
  <br>
  High-Performance Web Hosting & VPS Services
</p>

<p align="center">
  © 2025 ENGINYRING. All rights reserved.<br>
  <br>
  <a href="https://www.enginyring.com/en/webhosting">Web hosting</a> | 
  <a href="https://www.enginyring.com/en/virtual-servers">VPS hosting</a> | 
  <a href="https://www.enginyring.com/tools">Free DevOps tools</a>
</p>
