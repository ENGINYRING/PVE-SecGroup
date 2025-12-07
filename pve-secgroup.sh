#!/bin/bash
# PVE-SecGroup - Automated Proxmox Firewall Group Updater via BGPQ4
# Reads config from pve-secgroup.conf
# Run via cron: 0 2 * * * /usr/local/bin/pve-secgroup.sh

# ---------------------------------------------------------
# CONFIGURATION LOADING LOGIC
# ---------------------------------------------------------

# Get the directory where the script is physically located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Define search priority for the config file
POSSIBLE_PATHS=(
    "$(pwd)/pve-secgroup.conf"              # 1. Current working directory (Great for testing)
    "$SCRIPT_DIR/pve-secgroup.conf"         # 2. Directory where the script lives
    "/etc/pve-secgroup.conf"                # 3. Standard global location
    "/etc/pve-secgroup/pve-secgroup.conf"   # 4. Subdirectory global location
)

CONFIG_FILE=""

# Loop through paths and pick the first one that exists
for path in "${POSSIBLE_PATHS[@]}"; do
    if [[ -f "$path" ]]; then
        CONFIG_FILE="$path"
        break
    fi
done

# Validate Config Discovery
if [[ -z "$CONFIG_FILE" ]]; then
    echo "ERROR: Configuration file 'pve-secgroup.conf' not found."
    echo "Checked locations:"
    printf " - %s\n" "${POSSIBLE_PATHS[@]}"
    exit 1
fi

# Load Configuration
source "$CONFIG_FILE"

# ---------------------------------------------------------
# LOGGING SETUP
# ---------------------------------------------------------

# Logging function (Verbose: prints to StdOut AND Log file)
log() {
    local message="[$(date '+%Y-%m-%d %H:%M:%S')] $1"
    echo "$message" | tee -a "$LOG_FILE"
}

log "Starting Firewall Update Sequence..."
log "Loaded configuration from: $CONFIG_FILE"

# ---------------------------------------------------------
# EXECUTION LOGIC
# ---------------------------------------------------------

# Verify bgpq4 is installed
if ! command -v bgpq4 &> /dev/null; then
    log "ERROR: bgpq4 not found. Install with: apt-get install bgpq4"
    exit 1
fi

# Create backup of the INITIAL state
mkdir -p "$BACKUP_DIR"
cp "$FIREWALL_CONFIG" "$BACKUP_DIR/cluster.fw.$(date +%s).bak"
log "Backup created"

# We will work on a working copy of the config to allow multiple group updates
WORKING_CONFIG=$(mktemp)
cp "$FIREWALL_CONFIG" "$WORKING_CONFIG"
trap "rm -f $WORKING_CONFIG" EXIT

# ---------------------------------------------------------
# LOOP THROUGH GROUPS DEFINED IN CONFIG
# ---------------------------------------------------------
for GROUP_NAME in "${!TARGET_GROUPS[@]}"; do
    ASN_LIST="${TARGET_GROUPS[$GROUP_NAME]}"
    
    log "Processing Group: [$GROUP_NAME] | ASNs: $ASN_LIST"

    # Fetch prefixes with Aggregation (-A) and IPv4 (-4)
    PREFIXES=$(bgpq4 -4A -F "%n/%l\n" $ASN_LIST 2>/dev/null)
    
    # Check for empty result
    if [ -z "$PREFIXES" ]; then
        log "WARNING: No prefixes found for $ASN_LIST (or lookup failed). Skipping group [$GROUP_NAME]."
        continue
    fi

    PREFIX_COUNT=$(echo "$PREFIXES" | wc -l)
    log "  -> Fetched $PREFIX_COUNT aggregated prefixes."

    # Create a temp file for this specific loop iteration
    NEXT_STAGE_CONFIG=$(mktemp)

    # AWK: Remove old group block from WORKING_CONFIG and append new one
    awk -v group="$GROUP_NAME" -v prefixes="$PREFIXES" -v action="$RULE_ACTION" '
    BEGIN { 
        skipping = 0 
    }
    {
        # Check if this line starts the group we want to replace
        if (index($0, "[group " group "]") == 1) {
            skipping = 1
        }
        # If we hit another section and we were skipping, stop skipping
        else if (/^\[/ && skipping == 1) {
            skipping = 0
        }
    }
    # Only print lines if we are not skipping
    skipping == 0 { print }

    END {
        print ""
        print "[group " group "] # Updated " strftime("%Y-%m-%d %H:%M:%S")
        
        split(prefixes, arr, "\n")
        for (i in arr) {
            if (arr[i] != "") {
                # Format: IN REJECT -source x.x.x.x/x -log nolog
                print "IN " action " -source " arr[i] " -log nolog"
            }
        }
        # Ensure default behavior allows traffic OUT, but accepts established IN
        print "OUT ACCEPT -log nolog"
        print "IN ACCEPT -log nolog"
    }
    ' "$WORKING_CONFIG" > "$NEXT_STAGE_CONFIG"

    # Move the result of this iteration to be the input for the next
    mv "$NEXT_STAGE_CONFIG" "$WORKING_CONFIG"
    log "  -> Group [$GROUP_NAME] updated in working config."

done

# ---------------------------------------------------------
# FINAL APPLICATION
# ---------------------------------------------------------

# Validate the final config before applying
if ! grep -q "\[OPTIONS\]" "$WORKING_CONFIG"; then
    log "CRITICAL ERROR: Generated config is invalid (missing [OPTIONS]). Aborting."
    exit 1
fi

# Compare sizes/diff to ensure we arent deploying an empty file
FILE_SIZE=$(stat -c%s "$WORKING_CONFIG")
if [ "$FILE_SIZE" -lt 10 ]; then
    log "CRITICAL ERROR: Generated config is surprisingly small/empty. Aborting."
    exit 1
fi

# Apply Config
cp "$WORKING_CONFIG" "$FIREWALL_CONFIG"
log "All groups processed. Configuration applied to $FIREWALL_CONFIG"

# Reload firewall
if systemctl is-active --quiet pve-firewall; then
    systemctl restart pve-firewall
    if [ $? -eq 0 ]; then
        log "Firewall service restarted successfully"
    else
        log "WARNING: Failed to restart pve-firewall service"
        # Restore from backup on failure
        LATEST_BACKUP=$(ls -t "$BACKUP_DIR"/cluster.fw.*.bak | head -1)
        cp "$LATEST_BACKUP" "$FIREWALL_CONFIG"
        log "ERROR: Restored from backup due to restart failure"
        exit 1
    fi
else
    log "WARNING: pve-firewall service not running"
fi

log "Update sequence completed."
