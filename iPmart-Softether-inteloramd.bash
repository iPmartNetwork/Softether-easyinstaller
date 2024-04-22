#!/usr/bin/env bash
(( EUID != 0 )) && exec sudo -- "$0" "$@"
red='\033[0;31m'
green='\033[0;32m'
yellow='\033[0;33m'
plain='\033[0m'
clear
echo "
____________________________________________________________________________________
        ____                             _     _                                     
    ,   /    )                           /|   /                                  /   
-------/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__---/-__-
  /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) /(    
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/_____/___\__
"
echo "***** https://github.com/ipmartnetwork *****"
# User confirmation
read -rep $'!!! IMPORTANT !!!\n\nSoftEther VPN(v4.43-9799-rtm-2023.08.31) will be downloaded and compiled on your server.Do you want to continue? [[y/N]] ' response
case "$response" in
[yY][eE][sS]|[yY])

#remove needrestart for less interruption 
sudo sed -i "s/#\$nrconf{restart} = 'i';/\$nrconf{restart} = 'a';/" /etc/needrestart/needrestart.conf

# REMOVE PREVIOUS INSTALL
# Check for the original version
if [ -d "/opt/vpnserver" ]; then
  echo -e "${yellow}Softether is already installed. The script is attempting to create a backup.${plain}"
  echo -e "${red}USE 'Ctrl + C' to cancel it.${plain}"
  sudo systemctl stop softether-vpnserver.service
  sleep 2
  sudo mkdir /opt/backup
  sleep 2
  sudo cp -f /opt/vpnserver/vpn_server.config /opt/backup/vpn_server.config.bak
  sleep 2
  sudo cp -rf /opt/vpnserver/backup.vpn_server.config /opt/backup/backup.vpn_server.config 
  sleep 2
  sudo rm -rf /opt/vpnserver
  sudo systemctl disable vpnserver
fi

# Check for Update script
if [ -d "/opt/softether" ]; then
  echo -e "${yellow}Softether is already installed. The script is attempting to create a backup.${plain}"
  echo -e "${red}USE 'Ctrl + C' to cancel it.${plain}"
  sudo systemctl stop softether-vpnserver
  sleep 2
  sudo mkdir /opt/backup
  sleep 2
  sudo cp -f /opt/softether/vpn_server.config /opt/backup/vpn_server.config.bak
  sleep 2
  sudo cp -rf /opt/softether/backup.vpn_server.config /opt/backup/backup.vpn_server.config 
  sleep 2
  sudo rm -rf /opt/softether
  sudo systemctl disable softether-vpnserver
fi

# Start from here
# Perform apt update & install necessary software
clear
echo -e "${green}Updating Linux server.${plain}"
sudo apt-get update -y && sudo apt-get -o Dpkg::Options::="--force-confold" -y full-upgrade -y && sudo apt-get autoremove -y 
sleep 2


# Install some useful tools
clear
echo -e "${green}Install some useful tools.${plain}"
sudo apt-get install -y certbot && sudo apt-get install -y ncat && sudo apt-get install -y net-tools
sleep 2
# Install dependency
clear
echo -e "${green}Install dependency.${plain}"
sudo apt install -y gcc binutils gzip libreadline-dev libssl-dev libncurses5-dev libncursesw5-dev libpthread-stubs0-dev || exit
sleep 2
clear



# Download SoftEther
echo -e "${green}Download & Install SoftEther | Version 4.43 | Build 9799.${plain}.\n"
wget https://www.softether-download.com/files/softether/v4.43-9799-beta-2023.08.31-tree/Linux/SoftEther_VPN_Server/64bit_-_Intel_x64_or_AMD64/softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz || exit
sleep 2
tar xvf softether-vpnserver-v4.43-9799-beta-2023.08.31-linux-x64-64bit.tar.gz || exit
sleep 2
cd vpnserver || exit
sleep 2
apt install make -y || exit
sleep 5
make || exit
sleep 2
cd .. || exit
sleep 2
sudo mv vpnserver /opt/softether || exit
sleep 2
sudo /opt/softether/vpnserver start || exit
sleep 5
sudo /opt/softether/vpnserver stop || exit
sleep 5

# Create the service file with the desired content
echo -e "${green}Create the service file.${plain}.\n"
sudo tee /etc/systemd/system/softether-vpnserver.service > /dev/null << 'EOF'
[Unit]
Description=SoftEther VPN server
After=network-online.target
After=dbus.service

[Service]
Type=forking
ExecStart=/opt/softether/vpnserver start
ExecReload=/bin/kill -HUP \$MAINPID

[Install]
WantedBy=multi-user.target
EOF

# Reload the systemd daemon to recognize the new service
sudo systemctl daemon-reload || exit
sleep 2
# Enable the service to start on boot
sudo systemctl enable softether-vpnserver.service || exit
sleep 3
# Start the service
sudo systemctl start softether-vpnserver.service || exit
sleep 5
# enable IPv4 forwadring 
echo 1 > /proc/sys/net/ipv4/ip_forward || exit
sleep 2
cat /proc/sys/net/ipv4/ip_forward || exit

# Openig port
echo -e "${green}Openig port And Enable FireWall.${plain}.\n"
ufw allow ssh
ufw default allow outgoing
ufw default deny incoming
ufw enable
sudo ufw allow 22
sudo ufw allow 53
sudo ufw allow 443 || exit
sudo ufw allow 80
sudo ufw allow 992
sudo ufw allow 1194  || exit
sudo ufw allow 2080
sudo ufw allow 5555
sudo ufw allow 4500
sudo ufw allow 1701
sudo ufw allow 500
sudo ufw allow 500,4500,2080,53/udp
sudo ufw reload
sleep 5

# Restore backup
if [ -d "/opt/backup" ]; then
  clear
  echo -e "${green}Restoring backup.${plain}.\n"
  sudo systemctl stop softether-vpnserver
  sudo cp -f /opt/backup/vpn_server.config.bak /opt/softether/vpn_server.config
  sudo cp -rf /opt/backup/backup.vpn_server.config /opt/softether/
  sudo systemctl restart softether-vpnserver
fi

clear
# Security Close the extra ports
#read -rp "Do you want to Close the extra ports? 'y' or 'n'" -n 1 REPLY
#printf '\n' # (optional) move to a new line
#if [[ $REPLY =~ ^[Yy]$ ]]
#then
#  sudo ufw deny 2280
#  sudo ufw deny 2380
#  sudo ufw deny 1194
#  sudo ufw deny 2080
#  sudo ufw deny 4500
#  sudo ufw deny 1701
#  sudo ufw deny 500
#  sudo ufw deny 8280
#  echo -e "${green}Close the extra ports Successfully ${plain}.\n"
#else
#  echo -e "${red}Close the extra ports skipped ${plain}.\n"
#fi

# Security Dynamic DNS 
echo -e "${red} IMPORTANT, IF YOU DON'T KNOW, SKIP IT ${plain}."
read -rp "Do you want to Disable Dynamic DNS? 'y' or 'n'" -n 1 REPLY
printf '\n' # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  sudo systemctl stop softether-vpnserver
  sed -i 's/bool Disabled false/bool Disabled true/g' /opt/softether/vpn_server.config
  sed -i 's/bool DisableNatTraversal false/bool DisableNatTraversal true/g' /opt/softether/vpn_server.config
  sudo systemctl restart softether-vpnserver
  echo -e "${green}Dynamic DNS Disable Successfully ${plain}.\n"
else
  echo -e "${red}Dynamic DNS Disable skipped ${plain}.\n"
fi

# Set Certificate
read -rp "Do you want to set a certificate on your server? 'y' or 'n'" -n 1 REPLY
printf '\n' # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]
then
  printf 'enter your domain name?\n'
  read -r ser # This reads input from the user and stores it in the variable name
  printf 'enter your email address?\n'
  read -r email # This reads input from the user and stores it in the variable name
  if sudo certbot certonly --standalone --preferred-challenges http --agree-tos --email "$email" -d "$ser"
  then
    echo -e "${green}Certificate successfully installed and VPN server restarted.${plain}.\n"
  else
    echo -e "${red}Certificate installation failed.${plain}.\n"
  fi  
else
  echo -e "${yellow}Certificate installation skipped.${plain}.\n"
fi


# Add need-restart back again
sudo sed -i "s/#\$nrconf{restart} = 'a';/\$nrconf{restart} = 'i';/" /etc/needrestart/needrestart.conf

#Adding shortcut for Softether setting
alias vpncmd='sudo /opt/softether/vpncmd 127.0.0.1:5555'
echo "alias vpncmd='sudo /opt/softether/vpncmd 127.0.0.1:5555'" >> ~/.bashrc


clear
# BBR
echo -e "${red}BBR is a congestion control system that optimizes the transmission of data packets over a network. ${plain}.\n"
read -p "Do you want to install BBR? [y/N] " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]
then
  # installing
    echo "net.core.default_qdisc=fq" | tee -a /etc/sysctl.conf
    echo "net.ipv4.tcp_congestion_control=bbr" | tee -a /etc/sysctl.conf
    # Apply changes
    sysctl -p
    clear
    echo -e "${red} USE 'vpncmd' FOR Softether Setting ${plain}"
    echo "Have FUN ;)."
    echo "REBOOT Recommended."
else
  # Exit the script
  clear
  echo -e "${red} USE 'vpncmd' FOR Softether Setting ${plain}"
  echo "Have FUN ;)."
  echo "REBOOT Recommended."
  exit 0
fi
esac
echo "
____________________________________________________________________________________
        ____                             _     _                                     
    ,   /    )                           /|   /                                  /   
-------/____/---_--_----__---)__--_/_---/-| -/-----__--_/_-----------__---)__---/-__-
  /   /        / /  ) /   ) /   ) /    /  | /    /___) /   | /| /  /   ) /   ) /(    
_/___/________/_/__/_(___(_/_____(_ __/___|/____(___ _(_ __|/_|/__(___/_/_____/___\__
"

