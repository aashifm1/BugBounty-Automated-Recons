#!/bin/bash

LIVE="live.txt"
WAYBACK="wayback.txt"
PARAMS="params.txt"
JSFILES="jsfiles.txt"
SECRETJS="secret-js.txt"
GF_XSS="gf-xss.txt"
GF_SSRF="gf-ssrf.txt"
GF_REDIRECT="gf-redirect.txt"
ENDPOINTS="endpoints.txt"
HEADERS="headers.txt"

log() {
    echo -e "[\033[1;36m$(date +%H:%M:%S)\033[0m] $1"
}

# === Tool Check ===
for tool in waybackurls gf httpx hakrawler; do
    if ! command -v $tool &> /dev/null; then
        echo "[!] Tool '$tool' not found. Install it."
        exit 1
    fi
done

# === JS File Extraction ===
log "Extracting JS files from wayback..."
grep -iE '\.js($|\?)' "$WAYBACK" | sort -u > "$JSFILES"

# === JS Secret Finder (basic grep-based) ===
log "Finding potential secrets in JS files (basic grep)..."
while read url; do
    curl -s "$url" | grep -Eoi 'apikey|token|secret|key|authorization|bearer\s+[a-z0-9]+' >> "$SECRETJS"
done < "$JSFILES"

# === GF Pattern Matching (needs gf installed and templates set) ===
log "Analyzing params for potential XSS, SSRF, Redirects..."
gf xss < "$PARAMS" > "$GF_XSS"
gf ssrf < "$PARAMS" > "$GF_SSRF"
gf redirect < "$PARAMS" > "$GF_REDIRECT"

# === Endpoint Discovery ===
log "Discovering more endpoints with hakrawler..."
cat "$LIVE" | hakrawler -depth 2 -plain | sort -u > "$ENDPOINTS"

# === Header Analysis ===
log "Analyzing headers for CORS/CSP/Misconfigs..."
httpx -l "$LIVE" -title -web-server -tech-detect -status-code -location -follow-redirects -silent > "$HEADERS"

log "Advanced recon completed! Files generated:"
echo "- $JSFILES (JS file list)"
echo "- $SECRETJS (Secrets found in JS)"
echo "- $GF_XSS, $GF_SSRF, $GF_REDIRECT"
echo "- $ENDPOINTS (Hakrawler endpoints)"
echo "- $HEADERS (Header inspection)"

