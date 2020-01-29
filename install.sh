#!/bin/bash

# Make installer interactive and select normal mode by default.
INTERACTIVE="y"

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -n|--normal)
    FAIL2BAN="y"
    UFW="y"
    BOOTSTRAP="y"
    shift
    ;;
    -i|--externalip)
    EXTERNALIP="$2"
    ARGUMENTIP="y"
    shift
    shift
    ;;
    --bindip)
    BINDIP="$2"
    shift
    shift
    ;;
    -k|--privatekey)
    KEY="$2"
    shift
    shift
    ;;
    -f|--fail2ban)
    FAIL2BAN="y"
    shift
    ;;
    --no-fail2ban)
    FAIL2BAN="n"
    shift
    ;;
    -u|--ufw)
    UFW="y"
    shift
    ;;
    --no-ufw)
    UFW="n"
    shift
    ;;
    -b|--bootstrap)
    BOOTSTRAP="y"
    shift
    ;;
    --no-bootstrap)
    BOOTSTRAP="n"
    shift
    ;;
    --no-interaction)
    INTERACTIVE="n"
    shift
    ;;
    -h|--help)
    cat << EOL

Metrix Masternode installer arguments:

    -n --normal               : Run installer in normal mode
    -i --externalip <address> : Public IP address of VPS
    --bindip <address>        : Internal bind IP to use
    -k --privatekey <key>     : Private key to use
    -f --fail2ban             : Install Fail2Ban
    --no-fail2ban             : Do not install Fail2Ban
    -u --ufw                  : Install UFW
    --no-ufw                  : Do not install UFW
    -b --bootstrap            : Sync node using Bootstrap
    --no-bootstrap            : Do not use Bootstrap
    -h --help                 : Display this help text.
    --no-interaction          : Do not wait for wallet activation.

EOL
    exit
    ;;
    *)    # unknown option
    POSITIONAL+=("$1") # save it in an array for later
    shift
    ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

clear

# Make sure curl is installed
apt-get update
apt-get install -qqy curl jq
clear

# These should automatically find the latest version of Metrix

TARBALLURL=$(curl -s https://api.github.com/repos/TheLindaProjectInc/Metrix/releases/latest | grep browser_download_url | grep -e "metrix-linux-x64" | cut -d '"' -f 4)
TARBALLNAME=$(curl -s https://api.github.com/repos/TheLindaProjectInc/Metrix/releases/latest | grep browser_download_url | grep -e "metrix-linux-x64" | cut -d '"' -f 4 | cut -d "/" -f 9)
BOOTSTRAPURL="https://lindaproject.nyc3.digitaloceanspaces.com/metrix/bootstrap/metrix.zip"
BOOTSTRAPARCHIVE="metrix.zip"

#!/bin/bash

# Check if we are root
if [ "$(id -u)" != "0" ]; then
   echo "This script must be run as root." 1>&2
   exit 1
fi

## Create Swapfile
if [ -z $(cat /proc/swaps | grep /swapfile | cut -f 3) ]; then
  fallocate -l 3G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo -e "/swapfile none swap sw 0 0 \n" >> /etc/fstab
fi

# Check if we have enough memory
if [[ $(free -m | awk '/^Mem:/{print $2}') -lt 850 ]]; then
  echo "This installation requires at least 1GB of RAM.";
  exit 1
fi

# Check if we have enough disk space
if [[ $(df -k --output=avail / | tail -n1) -lt 10485760 ]]; then
  echo "This installation requires at least 10GB of free disk space.";
  exit 1
fi

# Install tools for dig and systemctl
echo "Preparing installation..."
apt-get install git dnsutils systemd -y > /dev/null 2>&1

# Check for systemd
systemctl --version >/dev/null 2>&1 || { echo "systemd is required. Are you using Ubuntu 16.04?"  >&2; exit 1; }

# Get our current IP
IPV4=$(dig +short myip.opendns.com @resolver1.opendns.com)
if [[ $IPV4 == *"connection timed out"* ]]; then
        IPV4=$(dig -4 TXT +short o-o.myaddr.l.google.com @ns1.google.com| tr -d \")
fi
IPV6=$(dig +short -6 myip.opendns.com aaaa @resolver1.ipv6-sandbox.opendns.com)
if [[ $IPV6 == *"connection timed out"* ]]; then
        IPV6=$(dig -6 TXT +short o-o.myaddr.l.google.com @ns1.google.com| tr -d \")
fi
if [ -z "$EXTERNALIP" ]; then
  if [ -n "$IPV4" ]; then
    EXTERNALIP="$IPV4"
  else
    EXTERNALIP="$IPV6"
  fi
fi
clear

if [[ $INTERACTIVE = "y" ]]; then
echo "
Metrix Masternode Installer
"

sleep 3
fi

USER=root

if [ -z "$FAIL2BAN" ]; then
  FAIL2BAN="y"
fi
if [ -z "$UFW" ]; then
  UFW="y"
fi
if [ -z "$BOOTSTRAP" ]; then
  BOOTSTRAP="y"
fi
INSTALLERUSED="#Used Basic Install"

USERHOME=$(eval echo "~$USER")

if [ -z "$ARGUMENTIP" ]; then
  read -erp "Server IP Address: " -i "$EXTERNALIP" -e EXTERNALIP
fi

if [ -z "$BINDIP" ]; then
    BINDIP=$EXTERNALIP;
fi

if [ -z "$KEY" ]; then
  read -erp "Masternode Private Key (e.g. 7edfjLCUzGczZi3JQw8GHp434R9kNY33eFyMGeKRymkB56G4324h # THE KEY YOU GENERATED EARLIER) : " KEY
fi

if [ -z "$FAIL2BAN" ]; then
  read -erp "Install Fail2ban? [Y/n] : " FAIL2BAN
fi

if [ -z "$UFW" ]; then
  read -erp "Install UFW and configure ports? [Y/n] : " UFW
fi

if [ -z "$BOOTSTRAP" ]; then
  read -erp "Do you want to use our bootstrap file to speed the syncing process? [Y/n] : " BOOTSTRAP
fi

clear

# Generate random passwords
RPCUSER=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 12 | head -n 1)
RPCPASSWORD=$(head /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 32 | head -n 1)

# update packages and upgrade Ubuntu
echo "Installing dependencies..."
apt-get -qq update
apt-get -qq upgrade
apt-get -qq autoremove
apt-get -qq install htop
apt-get -qq install git unzip aptitude

# Install Fail2Ban
if [[ ("$FAIL2BAN" == "y" || "$FAIL2BAN" == "Y" || "$FAIL2BAN" == "") ]]; then
  echo "Installing Fail2ban"
  aptitude -y -q install fail2ban
  # Reduce Fail2Ban memory usage - http://hacksnsnacks.com/snippets/reduce-fail2ban-memory-usage/
  echo "ulimit -s 256" | sudo tee -a /etc/default/fail2ban
  service fail2ban restart
fi

# Install UFW
if [[ ("$UFW" == "y" || "$UFW" == "Y" || "$UFW" == "") ]]; then
  echo "Installing UFW"
  apt-get -qq install ufw
  ufw default deny incoming
  ufw default allow outgoing
  ufw allow ssh
  ufw allow 33820/tcp
  yes | ufw enable
fi

# Install Metrix daemon
echo "Installing metrix daemon"
wget "$TARBALLURL"
tar -xzvf "$TARBALLNAME" -C /usr/local/bin
rm "$TARBALLNAME"

# Create .Metrixcore directory
mkdir "$USERHOME/.metrix"

# Install bootstrap file
if [[ ("$BOOTSTRAP" == "y" || "$BOOTSTRAP" == "Y" || "$BOOTSTRAP" == "") ]]; then
  echo "Installing bootstrap file..."
  wget "$BOOTSTRAPURL" && unzip $BOOTSTRAPARCHIVE -d "$USERHOME/.metrix/" && rm $BOOTSTRAPARCHIVE
fi

# Create Metrix.conf
touch "$USERHOME/.metrix/metrix.conf"

cat > "$USERHOME/.metrix/metrix.conf" << EOL
${INSTALLERUSED}
bind=[${BINDIP}]:52543
daemon=1
externalip=[${EXTERNALIP}]
listen=1
logtimestamps=1
masternode=1
masternodeaddr=[${EXTERNALIP}]
masternodeprivkey=${KEY}
maxconnections=256
rpcallowip=127.0.0.1
rpcpassword=${RPCPASSWORD}
rpcuser=${RPCUSER}
server=1
EOL

chmod 0600 "$USERHOME/.metrix/metrix.conf"
chown -R $USER:$USER "$USERHOME/.metrix"

sleep 1

cat > /etc/systemd/system/metrixd.service << EOL
[Unit]
Description=Metrix's distributed currency daemon
After=network-online.target
[Service]
Type=forking
User=${USER}
WorkingDirectory=${USERHOME}
ExecStart=/usr/local/bin/metrixd -conf=${USERHOME}/.metrix/metrix.conf -datadir=${USERHOME}/.metrix
ExecStop=/usr/local/bin/metrix-cli -conf=${USERHOME}/.metrix/metrix.conf -datadir=${USERHOME}/.metrix stop
Restart=on-failure
RestartSec=1m
StartLimitIntervalSec=5m
StartLimitInterval=5m
StartLimitBurst=3
[Install]
WantedBy=multi-user.target
EOL
systemctl enable metrixd
echo "Starting Metrixd, will check status in 60 seconds..."
systemctl start metrixd

sleep 60

if ! systemctl status metrixd | grep -q "active (running)"; then
  echo "ERROR: Failed to start metrixd. Please contact support."
  exit
fi

echo "Waiting for wallet to load..."
until su -c "metrix-cli getinfo 2>/dev/null | grep -q \"version\"" $USER; do
  sleep 1;
done

clear

cat << EOL

  Your blockchain is now syncing. This can take up to an hour to complete.

  When the chain is in sync, you need to start your masternode! 
  If you haven't already, please add this node to your masternode.conf file. Once you have 
  added the node, restart and unlock your Altitude wallet! Then, go 
  to the Masternodes tab, and click "Start ALL."

  To check the sync status of this node

  metrix-cli getinfo

  When fully in sync and the node is started from altitude

  metrix-cli masternode status

EOL


#if [[ $INTERACTIVE = "y" ]]; then
#  read -rp "Press Enter to continue after you've started the node in your wallet. " -n1 -s
#fi

#clear

#sleep 1
#su -c "/usr/local/bin/metrix-cli masternode local false" $USER
#sleep 1
#cleara
#su -c "/usr/local/bin/metrix-cli masternode status" $USER
#sleep 5

echo "" && echo "Masternode setup completed!" 
echo ""