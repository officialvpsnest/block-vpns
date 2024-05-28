#!/bin/bash

# Variables
VPNInput="/tmp/vpn_subnets.txt"
VPNOutput="/tmp/vpn_ips.txt"
DatacenterInput="/tmp/datacenter_subnets.txt"
DatacenterOutput="/tmp/datacenter_ips.txt"
BlockedIPList="/tmp/blocked_ips.txt"
CombinedCSV="/tmp/combined_summary.csv"

# Function to delete older files
delete_old_files() {
    rm -f "$VPNOutput" "$DatacenterOutput" "$BlockedIPList" "$CombinedCSV"
}

# Check if prips is Installed
if ! [ -x "$(command -v prips)" ]; then
  echo && echo " [-] Error: Please install 'prips' before running this script." && echo
  exit 1
fi

# Function to block IP addresses using UFW
block_ips() {
    while IFS= read -r ip; do
        sudo ufw deny from "$ip"
        echo "$ip" >> "$BlockedIPList"
    done < "$1"
}

# Function to summarize IP addresses into CSV
summarize_ips() {
    sort -u "$1" >> "$2"
}

# Wordcount
echo && echo " [+] Converting Subnets to IPs..."

# Download List
wget -q -N https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/vpn/ipv4.txt -O "$VPNInput"
wget -q -N https://raw.githubusercontent.com/X4BNet/lists_vpn/main/output/datacenter/ipv4.txt -O "$DatacenterInput"

# Delete older files
delete_old_files

# Check and block IP addresses
while IFS= read -r subnet; do
  prips "$subnet" >> "$VPNOutput"
done < "$VPNInput"
sed -i '1d' "$VPNOutput"

while IFS= read -r subnet; do
  prips "$subnet" >> "$DatacenterOutput"
done < "$DatacenterInput"
sed -i '1d' "$DatacenterOutput"

# Block IP addresses using UFW
block_ips "$VPNOutput"
block_ips "$DatacenterOutput"

# Summarize IP addresses into combined CSV
{
  summarize_ips "$VPNOutput" "/dev/stdout"
  summarize_ips "$DatacenterOutput" "/dev/stdout"
} | sort -u > "$CombinedCSV"

# Wordcount
echo && echo " [+] Combined Summary CSV" && echo && wc -l "$CombinedCSV" && echo

exit 0
