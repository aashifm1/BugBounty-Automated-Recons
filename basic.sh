#!/bin/bash

INPUT="targets.txt"
SUBS="subdomains.txt"
LIVE="live.txt"
NUCLEI="nuclei.txt"
WAYBACK="wayback.txt"
PARAMS="params.txt"

# === Logging Function ===
log() {
    echo -e "[\033[1;32m$(date +%H:%M:%S)\033[0m] $1"
}

# === Tool Check ===
for tool in subfinder httpx nuclei waybackurls; do
    if ! command -v $tool &> /dev/null; then
        echo "[!] Tool '$tool' not found. Please install it."
        exit 1
    fi
done

# === Subdomain Enumeration ===
log "Finding subdomains..."
subfinder -dL "$INPUT" -silent -o "$SUBS"

# === Live Host Checking ===
log "Checking live domains..."
httpx -l "$SUBS" -silent -o "$LIVE"

# === Nuclei Scan ===
log "Running nuclei scans (panel, takeover, cve, exposure)..."
nuclei -l "$LIVE" -tags panel,takeover,cve,exposure -silent -o "$NUCLEI"

# === Wayback URLs ===
log "Fetching waybackurls..."
cat "$SUBS" | waybackurls | tee "$WAYBACK" | grep "=" > "$PARAMS"

log "Recon completed! Output files:"
echo "- $SUBS"
echo "- $LIVE"
echo "- $NUCLEI"
echo "- $WAYBACK"
echo "- $PARAMS"

