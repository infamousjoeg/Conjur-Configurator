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
3. Backups
4. Seeds
5. Logs

#### Ports
1. 443 - Used for secure communications.
2. 444 - Used for loadblancer verification that doesn't go over 443.
3. 5432 - Used for postgresql database replication to standby/follower instances.
4. 1999 - Used for streaming audit log information from follower instances.

### Option 2
The desired result of this option is to configure an already started conjur master/standby container as a master. The container from option 1 will be made into a conjur leader. There is a prompt for the loadbalancer DNS. This program will use this name for BOTH the hostname of the conjur leader instance as well as the container name. Avoid using names that are not supported by DNS and the word 'conjur'(conjur is a reserved name within the leader container). Also stay away from using 'localhost' as this will cause issues with networking.

### Option 3
The desired result of this option is to load in some basic conjur policies into a conjur environment. Note that the root policy is being loaded with the "--replace" flag which will overwrite any current root policy. The basic policies loaded are:

1. root
2. apps
3. apps/secrets

All of the policy files will are contained in the policy directory in this repo. There is a cli container that is spun up and connected to the leader instance. The policy files directory is mounted to /policy inside of the cli container. This allows for easy loading of policies without the need to copy files into the container. 

## Local Files
All local files are saved to a hidden directory in the user's home folder called '.conjur'. This is where the configuration file is stored as well as the volume mounts for the Conjur leader container. Here is a break down of the folders and files that are created:

| File or Folder name  | Purpose |
| ------------- |:-------------:|
| conjurconfig | This file contains information that is needed to re-run the setup program. This allows persistence for things like container IDs. |
| security | Location for the Docker seccomp.json file |
| configuration | Location for the DAP configuration file |
| backup | Allows backups to be available on the host server |
| seeds | Simplifies transferring seed files into the DAP container |
| logs | Provides direct access to the DAP logs locally |