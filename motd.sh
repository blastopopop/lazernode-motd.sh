
#!/bin/bash
# ==========================================
# Lazer Node Premium MOTD Installer
# ==========================================

set -e

if [ "$EUID" -ne 0 ]; then
    echo "Please run this script as root."
    exit 1
fi

echo "Installing Lazer Node Premium MOTD..."

# Backup PAM and MOTD configuration
cp -a /etc/pam.d/sshd /etc/pam.d/sshd.lazernode.bak
[ ! -f /etc/pam.d/login ] || cp -a /etc/pam.d/login /etc/pam.d/login.lazernode.bak

# Disable default MOTD scripts
chmod -x /etc/update-motd.d/* 2>/dev/null || true

# Disable existing PAM MOTD output and custom exec entries
sed -i -E '/pam_motd\.so|pam_exec\.so.*lazernode-motd/d' /etc/pam.d/sshd
[ ! -f /etc/pam.d/login ] || \
  sed -i -E '/pam_motd\.so|pam_exec\.so.*lazernode-motd/d' /etc/pam.d/login

cat > /usr/local/sbin/lazernode-motd <<'MOTD'
#!/bin/bash

GREEN='\033[38;5;82m'
CYAN='\033[38;5;51m'
MAGENTA='\033[38;5;213m'
YELLOW='\033[38;5;220m'
GRAY='\033[38;5;245m'
RESET='\033[0m'

HOSTNAME=$(hostname)
OS=$(. /etc/os-release && echo "$PRETTY_NAME")
KERNEL=$(uname -r)
UPTIME=$(uptime -p 2>/dev/null | sed 's/up //' || echo "Unknown")
CPU=$(top -bn1 2>/dev/null | awk '/Cpu\(s\)/ {printf "%.1f%%", 100-$8; exit}')
MEM_TOTAL=$(free -m | awk '/^Mem:/ {print $2}')
MEM_USED=$(free -m | awk '/^Mem:/ {print $3}')
MEM_PERC=0
[ "${MEM_TOTAL:-0}" -gt 0 ] && MEM_PERC=$((MEM_USED * 100 / MEM_TOTAL))
DISK=$(df -h / | awk 'NR==2 {print $3 " / " $2 " (" $5 ")"}')
IP=$(hostname -I 2>/dev/null | awk '{print $1}')
PROCS=$(ps -e --no-headers 2>/dev/null | wc -l)
USERS=$(who 2>/dev/null | wc -l)

echo
echo -e "${MAGENTA}"
cat <<'LOGO'
██╗      █████╗ ███████╗███████╗██████╗
██║     ██╔══██╗╚══███╔╝██╔════╝██╔══██╗
██║     ███████║  ███╔╝ █████╗  ██████╔╝
██║     ██╔══██║ ███╔╝  ██╔══╝  ██╔══██╗
███████╗██║  ██║███████╗███████╗██║  ██║
╚══════╝╚═╝  ╚═╝╚══════╝╚══════╝╚═╝  ╚═╝
                  NODE
LOGO
echo -e "${RESET}"

echo -e "${GREEN}Welcome to Lazer Node Infrastructure${RESET}"
echo -e "${CYAN}High Performance • Secure • Reliable Hosting${RESET}"
echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"

printf "${CYAN}%-16s${RESET} %s\n" "Hostname:" "$HOSTNAME"
printf "${CYAN}%-16s${RESET} %s\n" "Operating System:" "$OS"
printf "${CYAN}%-16s${RESET} %s\n" "Kernel:" "$KERNEL"
printf "${CYAN}%-16s${RESET} %s\n" "Uptime:" "$UPTIME"
printf "${CYAN}%-16s${RESET} %s\n" "CPU Usage:" "${CPU:-Unknown}"
printf "${CYAN}%-16s${RESET} %s / %s MB (%s%%)\n" "Memory:" "$MEM_USED" "$MEM_TOTAL" "$MEM_PERC"
printf "${CYAN}%-16s${RESET} %s\n" "Disk:" "$DISK"
printf "${CYAN}%-16s${RESET} %s\n" "Processes:" "$PROCS"
printf "${CYAN}%-16s${RESET} %s\n" "Users:" "$USERS"
printf "${CYAN}%-16s${RESET} %s\n" "IP:" "${IP:-Unavailable}"

echo -e "${GRAY}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${RESET}"
echo -e "${GREEN}Website:${RESET} https://lazernode.com"
echo -e "${MAGENTA}Lazer Node — Powering Your Game Servers${RESET}"
echo
MOTD

chmod 755 /usr/local/sbin/lazernode-motd

# Configure PAM to display the custom MOTD on SSH login
echo 'session optional pam_exec.so stdout /usr/local/sbin/lazernode-motd' >> /etc/pam.d/sshd

echo
echo "Lazer Node MOTD installed."
echo "Reconnect SSH to see the banner."
