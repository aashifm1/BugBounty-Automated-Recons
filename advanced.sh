#!/bin/bash

LIVE="live.txt"
PARAMS="params.txt"
WAYBACK="wayback.txt"
JSFILES="jsfiles.txt"
DEEPENDPOINTS="deep-endpoints.txt"
SECRETJS="secret-js.txt"
GF_XSS="gf-xss.txt"
GF_SSRF="gf-ssrf.txt"
GF_REDIRECT="gf-redirect.txt"
DALFOX_XSS="dalfox-xss.txt"
HEADERS="cors-headers.txt"

log() {
    echo -e "[\033[1;36m$(date +%H:%M:%S)\033[0m] $1"
}

check_tool() {
    if ! command -v $1 &>/dev/null; then
        echo "[!] Tool '$1' not found. Install it first."
        exit 1
    fi
}

# === Tool Checks ===
for tool in katana hakrawler gau gf dalfox httpx; do
    check_tool $tool
done

# === Deep Endpoint Discovery ===
log "Running katana, gau, and hakrawler for endpoint discovery..."
katana -list "$LIVE" -silent | tee -a "$DEEPENDPOINTS" >/dev/null
hakrawler -urls "$LIVE" -plain | tee -a "$DEEPENDPOINTS" >/dev/null
gau -providers wayback,commoncrawl,otx,urlscan -subs -o - < "$LIVE" | tee -a "$DEEPENDPOINTS" >/dev/null
sort -u "$DEEPENDPOINTS" -o "$DEEPENDPOINTS"

# === JavaScript Secrets Detection ===
log "Scanning JS files for secrets (using grep)..."
while read url; do
    curl -s "$url" | grep -Eoi 'apikey|token|secret|key|authorization|bearer\s+[a-z0-9]+' >> "$SECRETJS"
done < "$JSFILES"

# Optional: SecretFinder or LinkFinder if Python env is ready

# === GF Patterns ===
log "Applying gf patterns (xss, ssrf, redirect)..."
gf xss < "$PARAMS" > "$GF_XSS"
gf ssrf < "$PARAMS" > "$GF_SSRF"
gf redirect < "$PARAMS" > "$GF_REDIRECT"

# === Dalfox XSS Scan ===
log "Testing vulnerable XSS params with Dalfox..."
dalfox file "$PARAMS" -o "$DALFOX_XSS"

# === CORS/CSP/Misconfig Headers ===
log "Analyzing headers for misconfig (httpx)..."
httpx -l "$LIVE" -web-server -status-code -location -title -tech-detect -follow-redirects -silent > "$HEADERS"

# === Done ===
log "Advance recon completed. Files generated:"
echo "- $DEEPENDPOINTS (discovered endpoints)"
echo "- $SECRETJS (JS secrets)"
echo "- $GF_XSS, $GF_SSRF, $GF_REDIRECT (gf filters)"
echo "- $DALFOX_XSS (dalfox XSS report)"
echo "- $HEADERS (header misconfig data)"

