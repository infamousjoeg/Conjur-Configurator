# conjur-poc

Script is intended to install CyberArk Conjur Enterprise Secrets Manager

## Requirements

1. Supported OS (listed below) with sudo capability
2. Internet connectivity

## How To Use

1. Clone this repository
2. chmod +x setup.sh
3. run ./setup.sh
4. Select option 1 to deploy a leader/standby container. 
5. Select option 2 to configure the container. This will configure the container deployed with option 1 as a leader. An admin password will be randomly generated. SAVE THE PASSWORD!
6. (Optional) Select option 3 to deploy the conjur cli container as well as load some generic policies. 

## Tested Operating Systems

- CentOS 7.x
- MacOS 10.15.7
- Ubuntu 18.x