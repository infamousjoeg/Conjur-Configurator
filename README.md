# Conjur Configurator

This script is intended to install CyberArk Conjur Enterprise Secrets Manager through an interactive menu system. 

## Requirements

1. Supported OS (listed below) with sudo capability
2. Internet connectivity (Unless you have the Conjur and Conjur CLI images saved and ready for an import)
3. Docker(CE/EE)

## How To Use

1. Clone this repository(or download the zip package)
2. chmod +x setup.sh
3. run ./setup.sh
4. Select option 1 to deploy a leader/standby container. 
5. Select option 2 to configure the container. This will configure the container deployed with option 1 as a leader. An admin password will be randomly generated. SAVE THE PASSWORD!
6. (Optional) Select option 3 to deploy the conjur cli container as well as load some generic policies. 
7. (Optional) Select option 4 to create a seed file for configuring a follower. 

## Tested Operating Systems

- CentOS 7.x
- MacOS 10.15.7,11.1
- Ubuntu 18.x,19.x,20.x
- RHEL 7.6

## Explanation of options

### Option 1
The desired result of this option is to start a Master/Standby container with all of the appropriate docker container options. The options that it enables are as follows:
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
This option will launch and configure a conjur cli container. This is required before performing option 4. 

### Option 4
The desired result of this option is to load in some basic conjur policies into a conjur environment. Note that the root policy is being loaded with the "--replace" flag which will overwrite any current root policy. The basic policies loaded are:

1. root
2. apps
3. conjur
4. conjur/authn-iam/prod
5. conjur/authn-k8s/prod
6. conjur/seed-generation
7. conjur/authn-azure/prod
8. tanzu
9. secrets

All of the policy files will are contained in the policy directory in this repo. There is a cli container that is spun up and connected to the leader instance. The policy files directory is mounted to /policy inside of the cli container. This allows for easy loading of policies without the need to copy files into the container. This option can be use to reload policies after changes. 

### Option 5
This option will create a seed file for a follower. You will be prompted for the follwer's DNS name. This could be a loadblancer DNS name that sits in front of the follwer(s). Note that for loadbalancers we will have to set the trusted proxy address in Conjur. The loadbalancer will have to be configured with Forward-for so that Conjur can see the original IP of the incoming request if host/ip security is required. 

### Option 9
This option will remove all containers stood up by this program. It will also show all of the configuration file settings before deleting the file. The folder containing the configuration (file $HOME/.config/cybr/) is NOT deleted in case there are other entries. The mounted folders to the container image is also retained in case there are files you'd like to review. 

## Local Files
All local files are saved to a hidden directory in the user's home folder called '.config/cybr'. This is where the configuration file is stored as well as the volume mounts for the Conjur leader container. Here is a break down of the folders and files that are created:

| File or Folder name  | Purpose |
| ------------- |:-------------:|
| conjurconfig | This file contains information that is needed to re-run the setup program. This allows persistence for things like container IDs. |
| security | Location for the Docker seccomp.json file |
| configuration | Location for the DAP configuration file |
| backup | Allows backups to be available on the host server |
| seeds | Simplifies transferring seed files into the DAP container |
| logs | Provides direct access to the DAP logs locally |

## Explanation of Policy files
The policy files bundled with this program are meant to be a reference for your expansion. They are not a definitive framework for how you should structure your policies. The emphasis has been placed on ease of reading and following the flow of the files. 

### root.yml
This is your main policy which all of your other policies are held. It defines a few users and a few groups. It also shows how to add users to the groups. 

### apps.yml
This policy is a sub policy off of root. We have 2 hosts defined in it's own 'hosts' policy. This was done as a grouping mechanism to have a single spot for your hosts. We then create a 'CI' and 'CD' policy with some layers. We then add the appropriate host to the correct layer based on their role. Ansible == CD and Jenkins == CI. 

### conjur.yml
This policy controls all of the special integrations that are available to Conjur. These policies include AWS, Kubernetes, and Seed Generator authenticators. 

#### aws.yml (sub policy in Conjur policy)
This is the main AWS policy that contains a placeholder for AWS apps. 

#### kubernetes.yml (sub policy in Conjur policy)
This is the main kubernetes policy that containers placeholders for k8s applications. The CA is already initialized if you ran option 3 in the main menu.

#### seedgeneration.yml (sub policy in Conjur policy)
This controls the automatic seed generator. Primarily used for deployment of followers in k8s in an automatic way.

#### azure.yml (sub policy in Conjur policy)
This policy controls the authn-azure webservice and the hosts for azure. These hosts have already been granted permission to access the dummy secrets. 

### tanzu.yml
This policy creates a framework to work with VMWare Tanzu. The policy for the Tanzu is 'tanzu/production'. This is what the serice broker should be configured to control. There is a host created called 'host/tanzu/tanzu-service-broker' and has ownership of the 'tanzu/production' policy. 

### secrets.yml
This contains some generic secrets that will be populated with dummy data. All of the hosts created will have permissions to these secrets. 