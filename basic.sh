#!/bin/bash

INPUT="targets.txt"
SUBS="subdomains.txt"
LIVE="live.txt"
NUCLEI="nuclei.txt"
WAYBACK="wayback.txt"
PARAMS="params.txt"

log() {
    echo -e "[\033[1;32m$(date +%H:%M:%S)\033[0m] $1"
}

# Check required tools
for tool in subfinder httpx nuclei waybackurls; do
    if ! command -v $tool &> /dev/null; then
        echo "[!] Tool '$tool' not found. Please install it."
        exit 1
    fi
done

log "Starting subdomain enumeration..."
subfinder -dL "$INPUT" -silent -o "$SUBS"

log "Checking live domains..."
httpx -l "$SUBS" -silent -o "$LIVE"

log "Running nuclei scans (panel, takeover, cve, exposure)..."
nuclei -l "$LIVE" -tags panel,takeover,cve,exposure -silent -o "$NUCLEI"

log "Fetching wayback URLs..."
waybackurls -iL "$SUBS" > "$WAYBACK"  # Writing to file directly
grep "=" "$WAYBACK" > "$PARAMS"  # Extracting parameters

log "Basic recon completed! Output files:"
echo "- $SUBS"
echo "- $LIVE"
echo "- $NUCLEI"
echo "- $WAYBACK"
echo "- $PARAMS"
