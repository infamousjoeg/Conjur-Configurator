#!/bin/bash
#Conjur POC Install - Master install and base policies 

#menu
function_menu(){
    until [ "$selection" = "0" ]; do
      clear;
      echo "Welcome to the Conjur Enterprise Standup Utility! (CESU)"
      echo "This program can help you configure many different types of Conjur Enterprise instances."
      echo ""
      echo "    	1  -  Deploy Conjur Enterprise Leader container."
      echo "    	2  -  Configure Conjur Enterprise container as Leader."
      echo "    	3  -  Configure POC Policies."
      echo "    	4  -  Remove Conjur Enterprise container."
      echo "    	0  -  Exit"
      echo ""
      echo -n "  Enter selection: "
      read selection
      echo ""
      case $selection in
        1 ) clear ; deploy_leader_container ; press_enter ;;
        2 ) clear ; configure_leader_container ; press_enter ;;
        3 ) clear ; poc_configure ; press_enter ;;
        4 ) clear ; remove_container ; press_enter ;;
        0 ) clear ; exit ;;
        * ) clear ; incorrect_selection ; press_enter ;;
      esac
    done
}

press_enter() {
  echo ""
  echo -n "	Press Enter to continue "
  read
  clear
}

#Handle incorrect selection
incorrect_selection() {
    echo "Incorrect selection! Try again."
}

#check that machine is ready for installation
prereq_check(){
    #figure out if Docker is installed
    if ! command -v docker &> /dev/null
    then
      echo "Docker not found. Please install docker."
      exit 1
    else
      echo "Docker Installed"
    fi
    if ! docker info >/dev/null 2>&1; 
    then
      echo "Docker daemon doesn't appear to be running."
      exit 1
    else
      echo "Docker daemon appears to be running."
    fi
    if curl -Is https://hub.docker.com | head -n 1 | grep "200" &> /dev/null
    then
      echo "Can connect to dockerhub and will pull images directly"
      docker pull captainfluffytoes/csme:latest &> /dev/null
      docker pull cyberark/conjur-cli:5-latest &> /dev/null
      conjur_image=captainfluffytoes/csme:latest
      cli_image=cyberark/conjur-cli:5-latest
    else
      echo "Can't connect to dockerhub. Checking for local image."
    fi
}

#Deploy the Conjur Enterprise Leader Container
deploy_leader_container(){
    #Check for prereqs
    prereq_check;
    echo "All requirement checks have passed. Starting configuration of Conjur Enterprise Leader Container."
    echo -n "Enter the FQDN of Conjur: "
    read fqdn
    echo "Creating local folders."
    mkdir -p {security,configuration,backup,seeds,logs}
    echo "Creating Conjur Docker network."
    docker network create conjur &> /dev/null
    echo "Starting container."
    leader_container_id=$(docker container run \
    --name $fqdn \
    --detach \
    --network conjur \
    --restart=unless-stopped \
    --security-opt seccomp=unconfined \
    --publish "443:443" \
    --publish "444:444" \
    --publish "5432:5432" \
    --publish "1999:1999" \
    --volume configuration:/opt/cyberark/dap/configuration:Z \
    --volume security:/opt/cyberark/dap/security:Z \
    --volume backups:/opt/conjur/backup:Z \
    --volume seeds:/opt/cyberark/dap/seeds:Z \
    --volume logs:/var/log/conjur:Z \
    $conjur_image)
    echo "Leader/Standby Container deployed!"
}

#Configure Conjur Enterprise Leader container as leader.
configure_leader_container(){
  echo "Checking to make sure container is currently running."
  if docker container inspect $leader_container_id &> /dev/null
  then
    echo "Found container $leader_container_id running. Configuring as Leader."
    admin_password=$(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c${1:-32})
    echo ""
    echo -n "Please enter company name: "
    read company_name
    docker exec $leader_container_id evoke configure master --accept-eula --hostname $fqdn --admin-password $admin_password $company_name
    echo "Conjur Leader successfully configured!!!"
    echo "Admin Password is: $admin_password"
  else
    echo "Couldn't find container $leader_container_id running. Please stand up a leader/standby container from the main menu."
  fi
}

#remove containers that have been configured
remove_container(){
  echo "Removing leader container."
  docker container rm -f $leader_container_id
  echo "Removing CLI container."
  docker container rm -f $cli_container_id
  echo "Removing docker network."
  docker network rm conjur
}

poc_configure(){
#create CLI container
echo "Standing up the CLI container."
cli_container_id=$(docker container run -d --name conjur-cli --network conjur --restart=unless-stopped -v policy:/policy --entrypoint "" cyberark/conjur-cli:5 sleep infinity)

#set the company name in the cli-retrieve-password.sh script
echo "Updating password retreive script with correct values."
sed -i "s/master_name=.*/master_name=$fqdn/g" policy/cli-retrieve-password.sh
sed -i "s/company_name=.*/company_name=$company_name/g" policy/cli-retrieve-password.sh

#Init conjur session from CLI container
echo "Configured CLI container to talk to leader."
docker exec -i $cli_container_id conjur init --account $company_name --url https://$fqdn <<< yes &> /dev/null

#Login to conjur and load policy
echo "Logging into leader as admin."
docker exec $cli_container_id conjur authn login -u admin -p $admin_password
echo "Loading root policy."
root_policy_output=$(docker exec $cli_container_id conjur policy load --replace root /policy/root.yml)
echo "Loading app policy."
app_policy_output=$(docker exec $cli_container_id conjur policy load apps /policy/apps.yml)
echo "loading secrets policy."
secrets_policy_output=$(docker exec $cli_container_id conjur policy load apps/secrets /policy/secrets.yml)
echo "Here is the users that were created:"
echo $root_policy_output
echo ""

# set values for passwords in secrets policy
echo "Creating dummy secret for ansible"
docker exec $cli_container_id conjur variable values add apps/secrets/cd-variables/ansible_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for electric flow"
docker exec $cli_container_id conjur variable values add apps/secrets/cd-variables/electric_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for openshift"
docker exec $cli_container_id conjur variable values add apps/secrets/cd-variables/openshift_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for docker"
docker exec $cli_container_id conjur variable values add apps/secrets/cd-variables/docker_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for aws"
docker exec $cli_container_id conjur variable values add apps/secrets/cd-variables/aws_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for azure"
docker exec $cli_container_id conjur variable values add apps/secrets/cd-variables/azure_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for kubernetes"
docker exec $cli_container_id conjur variable values add apps/secrets/cd-variables/kubernetes_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for puppet"
docker exec $cli_container_id conjur variable values add apps/secrets/ci-variables/puppet_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for chef"
docker exec $cli_container_id conjur variable values add apps/secrets/ci-variables/chef_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
echo "Creating dummy secret for jenkins"
docker exec $cli_container_id conjur variable values add apps/secrets/ci-variables/jenkins_secret $(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32) &> /dev/null
}

function_menu