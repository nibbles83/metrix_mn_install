# Metrix Masternode Installation Guide

Metrix masternodes can be configured in a Local "Hot" or local & remote "Hot/Cold" setup.

Hot/Cold setups generally provide better security if configured correctly, although can be more complex to setup for non technical users.

This guide will cover the configuration of both methods.


### [Local "Hot" Masternode](#local-masternode)

### [Local & Remote "Hot/Cold" Masternode](#hot-cold-masternode)


## Masternode Collateral Tiers

Metrix has multiple tiers of masternodes depending on the amount of coins you have to use as collateral. The rewards percentage is the same for all tiers.

The tier sizes are (in millions) **2, 5, 25. 50, 100**.

The reward for a 2 million node is 3200. A 5 million node is 2.5 times the size, so the reward is 8000.

In all cases of node size the coins must be sent to your local masternode wallet address in a single transaction. The wallet can then identifiy these coins for use as a masternode collateral.


## Local Masternode

A local masternode is self contained on your own home PC. To operate a masternode in this way requires that the PC is left running 24/7, masternodes also require a stable internet connection, so wireless network connectivity is not generally recommended.

### System Requirements
==========================

Most modern day PC's can run a local masternode. A general guide is to ensure you have approx 1GB memory and 10GB free HDD space. This is alongside any other tasks your PC may be performing.

Ensure your wallet is fully up-to-date [Latest Altitiude](https://github.com/TheLindaProjectInc/Altitude/releases/latest).  
Also ensure thet the core version is updated to the latest, go to **Help > Check for Metrix Core Update**.

Also ensure that your blockheight is fully in sync with the chain [Explorer](https://www.mystakingwallet.com/app/explorer).

For a node to start you need to ensure that other nodes and peers can communicate with yours. This requires that port 33820 is open externally. [Check here](https://www.yougetsignal.com/tools/open-ports/).  
Put your external IP address and port 33820 to test if the port is open.  
Assuming its closed you will need to consult your router/firewall documentations to ensure that this port is formwarded to your local PC.


### Funding the masternode
==========================

In Altitude click **Dashboard > Add Account**  
Choose a label for your masternode "MN1", then click **Create Account**  
Your new masternode label will appear in the main dashboard. Click that account and copy the address.

Send the full collateral amount to your MN1 address in the **Send** tab.  

Once the amount has been sent you now need to wait for 15 confirmations.

### Setup the masternode
==========================

Click **Masternodes > Setup Local masternode** in Altitude.  
The masternode collateral anmount should be detected and available to start as a local masternode.  

Click **Start Local**  

You masternode will then start after a few seconds.

The machine will need to remain running at all times for the masternode to work.

## Hot Cold Masternode

Hot/cold masternodes are made up of a cold wallet that stores your masternode collaterals, alongside a remote wallet containing no coins. This remote wallet needs to remain on at all times and advertises to the network that you have the collateral required.  

Often the remote side is created on a cloud VPS provider. This generally provides better uptime of the node and more security as the coins only exist on the ofline side of the configuration.  

The most common servicesmused with our wallets are [Digital Ocean](https://www.digitalocean.com/) and [Vultr](https://www.vultr.com/).  

We also recommend you do not use elastic cloud services like AWS or Google Cloud for your masternode. These services generally require advanced network knowledge to correctly configure.

### Funding the masternode
==========================

In Altitude click **Dashboard > Add Account**  
Choose a label for your masternode "MN1", then click **Create Account**  
Your new masternode label will appear in the main dashboard. Your cold wallet can control multiple masternodes of varying collateral sizes. For each masternode create a new label/address pair. You will also need a remote VPS per masternode.

Send the full collateral amount to your MN1 address in the **Send** tab.  

Once the amount has been sent you now need to wait for 15 confirmations.

### Setup the masternode
==========================

If you haven't already, create an account with a VPS provider and create your first VPS system. Ensure that its size meets the minimum requirements, also ensure that you open port 22 and 33820 through the VPS provider firewall. Your VPS provider will provide documatation on these steps for their environment.  
Make a note of the Public IP addresses that you are allocated, you will need these later.

Generate your Masternode Private Key

In your wallet, open Tools -> Debug console and run the following command to get your masternode key:

`masternode genkey`

Please note: If you plan to set up more than one masternode, you need to create a key with the above command for each one. These keys are not tied to any specific masternode, but each masternode you run requires a unique key.

Run this command to get your output information:

`masternode outputs`

Copy both the key and output information to a text file.

Click **Masternodes > Add Remote Masternode** in Altitude.  

For each masternode fill in the fields.
```
Alias = Label  
Masternode IP:Port = Public IP and port of your VPS.  
Masternode Private Key = The output from genkey  
Masternode TRX Hash = Large hash from outputs
Masternode TRX index = Single digit from outputs
```

Restart and unlock your wallet.  

SSH (Putty on Windows, Terminal.app on macOS) to your VPS, login as root and run the following command:

`bash <( curl https://raw.githubusercontent.com/nibbles83/metrix_mn_install/master/install.sh )`  

If you get the error "bash: curl: command not found", run this first: `apt -y install curl`

The script will prompt to confirm your masternode public IP and will require the masternode genkey (Copy a genkey from the text file created above, in PuTTY right click to paste).  

The installation will proceed and the wallet will start.
You should now wait for the wallet to complete the sync.  
Type `metrix-cli getinfo | grep blocks` and compare it with the current [Explorer](https://www.mystakingwallet.com/app/explorer) blockcount.

When your node is in sync open the masternode tab in Altitude and click the Start-All button.

It can take a few moments to start the node. Altitude will report on the status of this action.