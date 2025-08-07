#!/bin/bash

LIVE="live.txt"
WAYBACK="wayback.txt"
PARAMS="params.txt"
JSFILES="jsfiles.txt"
DEEPENDPOINTS="deep-endpoints.txt"
SECRETJS="secret-js.txt"
GF_XSS="gf-xss.txt"
GF_SSRF="gf-ssrf.txt"
GF_REDIRECT="gf-redirect.txt"
DALFOX_XSS="dalfox-xss.txt"
HEADERS="headers.txt"

log() {
    echo -e "[\033[1;36m$(date +%H:%M:%S)\033[0m] $1"
}

check_tool() {
    if ! command -v $1 &>/dev/null; then
        echo "[!] Tool '$1' not found. Please install it."
        exit 1
    fi
}

# Check required tools
for tool in katana hakrawler gau gf dalfox httpx curl; do
    check_tool $tool
done

log "Extracting JS files from wayback URLs..."
grep -iE '\.js($|\?)' "$WAYBACK" | sort -u > "$JSFILES"

log "Running deep endpoint discovery with katana, hakrawler, and gau..."
katana -list "$LIVE" -silent | tee -a "$DEEPENDPOINTS" >/dev/null
hakrawler -urls "$LIVE" -plain | tee -a "$DEEPENDPOINTS" >/dev/null
gau -subs -o - < "$LIVE" | tee -a "$DEEPENDPOINTS" >/dev/null
sort -u "$DEEPENDPOINTS" -o "$DEEPENDPOINTS"

log "Scanning JS files for potential secrets..."
> "$SECRETJS"  # Clear file before appending
while read -r url; do
    curl -s "$url" | grep -Eoi 'apikey|token|secret|key|authorization|bearer\s+[a-z0-9]+' >> "$SECRETJS"
done < "$JSFILES"

log "Applying gf patterns for XSS, SSRF, and Redirect..."
gf xss < "$PARAMS" > "$GF_XSS"
gf ssrf < "$PARAMS" > "$GF_SSRF"
gf redirect < "$PARAMS" > "$GF_REDIRECT"

log "Running Dalfox XSS scan on parameters..."
dalfox file "$PARAMS" -o "$DALFOX_XSS"

log "Analyzing headers for misconfigurations..."
httpx -l "$LIVE" -web-server -status-code -location -title -tech-detect -follow-redirects -silent > "$HEADERS"

log "Advanced recon completed! Output files:"
echo "- $DEEPENDPOINTS (discovered endpoints)"
echo "- $SECRETJS (JS secrets)"
echo "- $GF_XSS, $GF_SSRF, $GF_REDIRECT (gf filters)"
echo "- $DALFOX_XSS (Dalfox XSS report)"
echo "- $HEADERS (header misconfig data)"
