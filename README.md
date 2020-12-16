# Conjur Configurator

This script is intended to install CyberArk Conjur Enterprise Secrets Manager through an interactive menu system. 

## Requirements

1. Supported OS (listed below) with sudo capability
2. Internet connectivity
3. Docker(CE/EE)

## How To Use

1. Clone this repository(or download the zip package)
2. chmod +x setup.sh
3. run ./setup.sh
4. Select option 1 to deploy a leader/standby container. 
5. Select option 2 to configure the container. This will configure the container deployed with option 1 as a leader. An admin password will be randomly generated. SAVE THE PASSWORD!
6. (Optional) Select option 3 to deploy the conjur cli container as well as load some generic policies. 

## Tested Operating Systems

- CentOS 7.x
- MacOS 10.15.7,11.1
- Ubuntu 18.x,19.x,20.x

## Explanation of options

### Option 1
The desried result of this option is to start a Master/Standby container with all of the appropriate docker container options. The options that it enables are as follows:
#### Volumes
1. Security
2. Configuration
3. backups
4. seeds
5. logs

#### Ports
1. 443
2. 444
3. 5432
4. 1999

### Option 2
The desired result of this option is to configure an already started conjur master/standby container as a master.

### Option 3
The desired result of this option is to load in some basic conjur policies into a conjur environment. Note that the root policy is being loaded with the "--replace" flag which will overwrite any current root policy. 