## Bug Bounty Recons
This is automated shell script for recon for bug bounty. This works in structured format. This format takes input from targets.txt file.


## Step-by-Step Method

Create a targets.txt
```bash
nano targets.txt
```
## Automation process
This automation shouod be done in order which take input from one another. This recons are especially for **wildcard** domains.

Basic recon (Level-1)
```bash
bash basic.sh
# Output: subdomains.txt, live.txt, nuclei.txt, wayback.txt, params.txt.
```
Medium recon (Level-2)
```bash
bash medium.sh
# Output: jsfiles.txt, secret-js.txt, gf-xss.txt, gf-ssrf.txt, gf-redirect.txt, endpoints.txt headers.txt.
```
Advanced recon (Level-3)
```bash
bash advanced.sh
# Output: deep-endpoints.txt, dalfox-xss.txt, cors-headers.txt.
```
