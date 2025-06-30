#!/bin/bash

# Color codes for output
GREEN="\e[32m"
RED="\e[31m"
YELLOW="\e[33m"
CYAN="\e[36m"
RESET="\e[0m"

banner() {
  echo -e "${CYAN}"
  echo "::::::::::: :::    ::: :::    ::: ::::    ::: :::::::::  :::::::::: :::::::::         ::::::::  ::::::::::: ::::::::::       :::::::::::  ::::::::   ::::::::  :::        :::    ::: ::::::::::: ::::::::::: "
  echo "    :+:     :+:    :+: :+:    :+: :+:+:   :+: :+:    :+: :+:        :+:    :+:       :+:    :+:     :+:     :+:                  :+:     :+:    :+: :+:    :+: :+:        :+:   :+:      :+:         :+:     "
  echo "    +:+     +:+    +:+ +:+    +:+ :+:+:+  +:+ +:+    +:+ +:+        +:+    +:+       +:+            +:+     +:+                  +:+     +:+    +:+ +:+    +:+ +:+        +:+  +:+       +:+         +:+     "
  echo "    +#+     +#++:++#++ +#+    +:+ +#+ +:+ +#+ +#+    +:+ +#++:++#   +#++:++#:        +#+            +#+     :#::+::#             +#+     +#+    +:+ +#+    +:+ +#+        +#++:++        +#+         +#+     "
  echo "    +#+     +#+    +#+ +#+    +#+ +#+  +#+#+# +#+    +#+ +#+        +#+    +#+       +#+            +#+     +#+                  +#+     +#+    +#+ +#+    +#+ +#+        +#+  +#+       +#+         +#+     "
  echo "    #+#     #+#    #+# #+#    #+# #+#   #+#+# #+#    #+# #+#        #+#    #+#       #+#    #+#     #+#     #+#                  #+#     #+#    #+# #+#    #+# #+#        #+#   #+#      #+#         #+#     "
  echo "    ###     ###    ###  ########  ###    #### #########  ########## ###    ###        ########      ###     ###                  ###      ########   ########  ########## ###    ### ###########     ###      "
  echo -e "${RESET}"
}

install_ctf_tools() {
  echo -e "${YELLOW}[*] Updating package lists...${RESET}"
  sudo apt update

  echo -e "${YELLOW}[*] Installing required CTF tools...${RESET}"
  sudo apt install -y masscan nmap gobuster ffuf whatweb nikto enum4linux ftp hydra searchsploit \
  metasploit-framework wget

  echo -e "${YELLOW}[*] Updating SearchSploit database...${RESET}"
  sudo searchsploit --update

  echo -e "${GREEN}[*] All tools installed and updated!${RESET}"
}

banner

echo -e "${GREEN}[+] Starting Thunder CTF Toolkit - Automated Recon and Exploitation${RESET}"

read -p "Do you want to install/update all required tools before starting? (y/N): " install_tools
if [[ "$install_tools" =~ ^[Yy]$ ]]; then
  install_ctf_tools
fi

read -p "Enter target IP or domain: " target
if [ -z "$target" ]; then
  echo -e "${RED}[-] Target is required! Exiting.${RESET}"
  exit 1
fi

# Create workspace folder
workspace="ctf_$target"
mkdir -p $workspace
cd $workspace || exit

echo -e "${YELLOW}[*] Phase 1: Fast port scan with masscan...${RESET}"
sudo masscan $target -p1-65535 --rate=1000 -oG masscan_$target.txt

# Extract ports from masscan output
ports=$(grep open masscan_$target.txt | cut -d' ' -f4 | tr '\n' ',' | sed 's/,$//')

echo -e "${YELLOW}[*] Phase 2: Nmap scan on discovered ports: $ports${RESET}"
nmap -p $ports -sC -sV -oN nmap_$target.txt $target

echo -e "${YELLOW}[*] Phase 3: Web technology detection...${RESET}"
whatweb $target > whatweb_$target.txt

# Directory busting with gobuster and ffuf (run in background to save time)
echo -e "${YELLOW}[*] Phase 4: Running Gobuster and ffuf directory scans...${RESET}"
gobuster dir -u http://$target -w /usr/share/wordlists/dirb/common.txt -o gobuster_$target.txt &  
ffuf -w /usr/share/wordlists/dirb/common.txt -u http://$target/FUZZ -o ffuf_$target.json -of json &

# SMB Enumeration if detected
if grep -q "445/open" nmap_$target.txt; then
  echo -e "${YELLOW}[*] Phase 5: SMB detected, running enum4linux...${RESET}"
  enum4linux $target > enum4linux_$target.txt
fi

# FTP anonymous login check
if grep -q "21/open" nmap_$target.txt; then
  echo -e "${YELLOW}[*] Phase 6: FTP detected, checking anonymous login...${RESET}"
  echo -e "user anonymous\npass anonymous\nquit" | ftp $target
fi

# Optional: SSH brute force with Hydra (ask user)
read -p "Do you want to run SSH brute force with Hydra? (y/N): " run_hydra
if [[ "$run_hydra" =~ ^[Yy]$ ]]; then
  read -p "Enter username list path: " userlist
  read -p "Enter password list path: " passlist
  echo -e "${YELLOW}[*] Running Hydra SSH brute force...${RESET}"
  hydra -L "$userlist" -P "$passlist" ssh://$target -t 4 -o hydra_ssh_results.txt
fi

# Searchsploit automatic vulnerability search
echo -e "${YELLOW}[*] Phase 7: Searching for exploits with SearchSploit...${RESET}"
services=$(grep "open" nmap_$target.txt | awk '{print $3,$4}')
echo "" > searchsploit_results.txt
while read -r service version; do
  if [[ -n "$service" ]]; then
    echo -e "${GREEN}[+] Searching exploits for: $service $version${RESET}"
    searchsploit "$service $version" >> searchsploit_results.txt
  fi
done <<< "$services"

# Automated Metasploit auxiliary scanner (optional)
read -p "Do you want to run Metasploit auxiliary scans? (y/N): " run_msf
if [[ "$run_msf" =~ ^[Yy]$ ]]; then
  msfconsole -q -x "use auxiliary/scanner/ssh/ssh_version; set RHOSTS $target; run; exit"
fi

# Download suspicious files found during enumeration
echo -e "${YELLOW}[*] Phase 8: Downloading suspicious files found during enumeration...${RESET}"
if [ -s gobuster_$target.txt ]; then
  mkdir -p downloads
  grep -E "\.php$|\.bak$|\.txt$|\.zip$" gobuster_$target.txt | while read -r line; do
    url="http://$target$line"
    echo -e "${GREEN}[+] Downloading: $url${RESET}"
    wget -q --show-progress -P downloads "$url"
  done
fi

# Flag hunting
echo -e "${YELLOW}[*] Phase 9: Searching for flags in downloaded files and current directory...${RESET}"
grep -r -E 'flag\{.*\}|CTF\{.*\}|THM\{.*\}' ./downloads ./ > flags_found.txt 2>/dev/null

# Wait for background processes to finish (gobuster, ffuf)
wait

# Summary Report
echo -e "${GREEN}\n[+] Thunder CTF Toolkit Automation Complete! Summary:${RESET}"
echo "- Nmap scan results: $(pwd)/nmap_$target.txt"
echo "- Gobuster results: $(pwd)/gobuster_$target.txt"
echo "- ffuf results: $(pwd)/ffuf_$target.json"
echo "- SMB enumeration: $(pwd)/enum4linux_$target.txt (if applicable)"
echo "- FTP anonymous login: Checked in terminal output"
echo "- Hydra SSH brute force results: $(pwd)/hydra_ssh_results.txt (if run)"
echo "- Searchsploit results: $(pwd)/searchsploit_results.txt"
echo "- Flags found: $(pwd)/flags_found.txt"
echo "- Downloaded files: $(pwd)/downloads/"

echo -e "${GREEN}Good luck hunting those flags with Thunder CTF Toolkit!${RESET}"
