# Thunder CTF Toolkit

**Thunder CTF Toolkit** is an automated, all-in-one reconnaissance and exploitation Bash script designed to streamline Capture The Flag (CTF) challenges and penetration testing workflows. It integrates popular tools like Masscan, Nmap, Gobuster, ffuf, WhatWeb, Nikto, Enum4linux, Hydra, SearchSploit, and Metasploit to automate scanning, enumeration, vulnerability discovery, and flag hunting.

---

## Features

- One-command installation of all required tools
- Fast port scanning with Masscan and detailed service enumeration with Nmap
- Automated web directory busting using Gobuster and ffuf
- Web technology detection via WhatWeb and Nikto
- SMB and FTP enumeration
- Optional SSH brute force with Hydra
- Automated exploit search with SearchSploit
- Integration with Metasploit auxiliary scanners
- Auto-download suspicious files for offline analysis
- Flag searching in downloaded files and scan outputs
- Clean, interactive CLI with a custom ASCII banner

---

## Prerequisites

- Kali Linux or Debian-based Linux distro
- Bash shell
- Internet connection (for tool installation and updates)
- Sudo privileges

---

## Installation

1. Clone this repository or download the script:

```bash
git clone https://github.com/yourusername/thunder-ctf-toolkit.git
cd thunder-ctf-toolkit
