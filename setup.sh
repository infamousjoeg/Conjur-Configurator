#!/bin/bash
#Conjur POC Install - Master install and base policies 

#variables
config_dir="$HOME/.config/cybr"
config_filename="conjurinstaller.config"
config_filepath="$config_dir/$config_filename"

#menu
import_menu(){
    until [ "$selection" = "0" ]; do
      clear;
      echo "Welcome to the Conjur Standup Utility! (CSU)"
      echo "This program can help you configure many different types of Conjur instances."
      echo ""
      echo "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
      echo "|||||||||||||A configuration file from a previous run has been detected!!!!|||||||||||||"
      echo "||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
      echo ""
      echo "    	1  -  Import previous configuration?"
      echo "    	2  -  Delete old configuration and start a new configuration?"
      echo "    	0  -  Exit"
      echo ""
      echo -n "  Enter selection: "
      read selection
      echo ""
      case $selection in
        1 ) clear ; import_config ; press_enter ; function_menu ; exit ;;
        2 ) clear ; delete_config ; create_config ; press_enter ; function_menu ; exit ;;
        0 ) clear ; exit ;;
        * ) clear ; incorrect_selection ; press_enter ;;
      esac
    done
}

function_menu(){
    until [ "$selection" = "0" ]; do
      clear;
      echo "Welcome to the Conjur Standup Utility! (CSU)"
      echo "This program can help you configure many different types of Conjur instances."
      echo ""
      echo "    	1  -  Deploy Conjur Leader/Standby container."
      echo "    	2  -  Configure Conjur container as Leader."
      echo "    	3  -  Configure POC Policies for Conjur."
      echo "    	4  -  Remove Conjur containers and configuration files."
      echo "    	0  -  Exit"
      echo ""
      echo -n "  Enter selection: "
      read selection
      echo ""
      case $selection in
        1 ) clear ; create_config ; docker_check ; press_enter ; deploy_leader_container_menu ; press_enter ;;
        2 ) clear ; configure_leader_container ; press_enter ;;
        3 ) clear ; poc_configure_menu ; press_enter ;;
        4 ) clear ; remove_container ; press_enter ;;
        0 ) clear ; exit ;;
        * ) clear ; incorrect_selection ; press_enter ;;
      esac
    done
}

deploy_leader_container_menu(){
    until [ "$selection" = "0" ]; do
      clear;
      echo "Deploy Conjur Leader/Standby container."
      echo ""
      echo "What method should be used to obtain the conjur image?"
      echo "    	1  -  Pull from dockerhub?"
      echo "    	2  -  Provide image name that pulls from an accessible private remote registry?"
      echo "    	3  -  Provide image name to use that's stored in the local regsitry?"
      echo "    	4  -  Provide image file for import into local registry?"
      echo "    	5  -  Return to main menu."
      echo "    	0  -  Exit"
      echo ""
      echo -n "  Enter selection: "
      read selection
      echo ""
      case $selection in
        1 ) clear ; pull_dockerhub "conjur_ent" ; press_enter ; deploy_leader_container ; press_enter ; function_menu ;;
        2 ) clear ; private_registry "conjur_ent" ; deploy_leader_container ; press_enter ; function_menu ;;
        3 ) clear ; local_registry "conjur_ent" ; deploy_leader_container ; press_enter ; function_menu ;;
        4 ) clear ; import_registry "conjur_ent" ; deploy_leader_container ; press_enter ; function_menu ;;
        5 ) clear ; function_menu ;;
        0 ) clear ; exit ;;
        * ) clear ; incorrect_selection ; press_enter ;;
      esac
    done
}

poc_configure_menu(){
    until [ "$selection" = "0" ]; do
      clear;
      echo "Deploy Conjur CLI container."
      echo ""
      echo "What method should be used to obtain the conjur cli image?"
      echo "    	1  -  Pull from dockerhub?"
      echo "    	2  -  Provide image name that pulls from an accessible private remote registry?"
      echo "    	3  -  Provide image name to use that's stored in the local regsitry?"
      echo "    	4  -  Provide image file for import into local registry?"
      echo "    	5  -  Return to main menu."
      echo "    	0  -  Exit"
      echo ""
      echo -n "  Enter selection: "
      read selection
      echo ""
      case $selection in
        1 ) clear ; pull_dockerhub "cli" ; press_enter ; poc_configure ; press_enter ; function_menu ;;
        2 ) clear ; private_registry "cli" ; press_enter ; poc_configure ; press_enter ; function_menu ;;
        3 ) clear ; local_registry "cli" ; press_enter ; poc_configure ; press_enter ; function_menu ;;
        4 ) clear ; import_registry "cli" ; press_enter ; poc_configure ; press_enter ; function_menu ;;
        5 ) clear ; function_menu ;;
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

config_check(){
  if [ -a $config_filepath ];
  then
    import_menu
  else
    create_config
    function_menu
  fi
}

import_config(){
  local count=$(wc -l < $config_filepath)
  if [ $count -eq 6 ]
  then
    echo "Configuration file is correct!"
    echo "||||||||||||||||||||||||||||||"
    echo "Contents of configuration file:"
    echo "$(cat $config_filepath)"
    source $config_filepath
  else
    echo "Configuration file is malformed."
    echo "Deleting configuration file and creating new blank configuration file."
    delete_config
    create_config
  fi
}

delete_config(){
  echo "Contents of old configuration file:"
  echo "$(cat $config_filepath)"
  echo ""
  echo "Deleting configuration file in $config_filepath."
  echo "Removing in memory variables."
  conjur_image=
  cli_image=
  fqdn_loadbalancer=
  leader_container_id=
  cli_container_id=
  company_name=
  rm -f $config_filepath
}

create_config(){
  if [ -a $config_filepath ];
  then
    echo "Configuration file exists."
  else
    echo "Creating configuration file \"$config_filename\" in \"$config_dir\"."
    mkdir -p $config_dir/
    cat <<EOF > $config_filepath
conjur_image=
cli_image=
fqdn_loadbalancer=
leader_container_id=
cli_container_id=
company_name=
EOF
fi
}

update_config(){
  if [[ "$OSTYPE" == "linux-gnu"* ]]
  then
    sed -i'' "s~$1=.*~$1=$2~" $config_filepath
  elif [[ "$OSTYPE" == "darwin"* ]]
  then
    sed -i '' "s~$1=.*~$1=$2~" $config_filepath
  else
    echo "Unknown OS for using sed command. Configuration fill will not be updated!" 
  fi
}

#check that machine has docker.
docker_check(){
  echo "Checking to see if docker is installed"
    #figure out if Docker is installed
    if ! command -v docker &> /dev/null
    then
      echo "Docker not found. Please install docker."
      press_enter;
      exit 1
    else
      echo "Docker Installed"
    fi
  echo "Checking if the daemon is accessible"
    if ! docker info >/dev/null 2>&1; 
    then
      echo "Docker daemon doesn't appear to be running or is inaccessible."
      echo "Returning to main menu."
      press_enter;
      function_menu;
    else
      echo "Docker daemon appears to be running."
    fi
    echo "All docker checks have passed."
}


pull_dockerhub(){
  if curl -Is https://hub.docker.com | head -n 1 | grep "200" &> /dev/null
  then
    echo "Can connect to dockerhub and will pull image directly"
        if [ $1 = "conjur_ent" ]
        then
          conjur_image=captainfluffytoes/csme:latest
          echo "Pulling image: $conjur_image"
          docker pull $conjur_image &> /dev/null
          update_config 'conjur_image' $conjur_image
        elif [ $1 = "cli" ]
        then
          cli_image=cyberark/conjur-cli:5-latest
          echo "Pulling image: $cli_image"
          docker pull $cli_image &> /dev/null
          update_config 'cli_image' $cli_image
        fi
  else
    echo "Can't connect to dockerhub."
    echo "Returning to previous menu."
    press_enter
    ${FUNCNAME[1]};
  fi
}

private_registry(){
  echo -n "Enter the image name (Use format registryAddress/imageName:ImageTag): "
  read image
  if ! docker pull $image
  then
    echo "Couldn't pull image from registry. Please verify network connection and/or verify that docker is properly authenticated."
    press_enter;
    ${FUNCNAME[1]};
  else
    echo "Connection to registry successful!"
    echo "Pulling image."
    docker pull $image &> /dev/null
    echo ""
    echo "Successfully pulled image!"
      if [ $1 = "conjur_ent" ]
      then
        update_config 'conjur_image' $image
        conjur_image=$image
      elif [ $1 = "cli" ]
      then
        update_config 'cli_image' $image
        cli_image=$image
      fi
  fi
}

local_registry(){
  echo -n "Enter the image name (Use format registryAddress/imageName:ImageTag): "
  read image
  if [ docker images --filter "reference=$image" = ""]
  then
    echo "Could not find image in local registry."
    echo "Returning to previous menu."
    press_enter
    ${FUNCNAME[1]};
  else
    echo "Found image in local registry: $image"
      if [ $1 = "conjur_ent" ]
      then
        update_config 'conjur_image' $image
        conjur_image=$image
      elif [ $1 = "cli" ]
      then
        cli_image=$image
        update_config 'cli_image' $image
      fi
  fi
}

import_registry(){
  echo "Scanning current directory for for saved image file."
  if [ $(find conjur-app*) &> /dev/null ] && [ $1 = "conjur_ent" ]
  then
    echo "Found local appliance file."
    tarname=$(find conjur-app*)
    conjur_image=$(docker load -i $tarname)
    conjur_image=$(echo $conjur_image | sed 's/Loaded image: //')
    update_config 'conjur_image' $conjur_image
  elif [ $(find conjur-cli*) &> /dev/null ] && [ $1 = "cli" ]
  then
    echo "Found local cli file."
    tarname=$(find conjur-cli*)
    cli_image=$(docker load -i $tarname)
    cli_image=$(echo $cli_image | sed 's/Loaded image: //')
    update_config 'cli_image' $cli_image
  else
    echo "Can't find local image in current directory."
    echo "Please contact your CyberArk Engineer to obtain the image file."
    echo "Returning to previous menu."
    press_enter;
    ${FUNCNAME[1]};
  fi
}

deploy_leader_container(){    
    echo "Starting configuration of the leader container."
    echo ""
    echo -n "Enter the DNS name for the Conjur Leader and Standby instance(s) load balancer (Name can not be \"localhost\" or \"conjur\" or container any spaces): "
    read fqdn_loadbalancer
    if [[ $fqdn_loadbalancer = *" "* ]] || [[ $fqdn_loadbalancer = localhost ]] || [[ $fqdn_loadbalancer = conjur ]]
    then
      echo "Load balancer DNS name as "$fqdn_loadbalancer" is not supported."
      echo "The name can not:"
      echo " - Contain any spaces."
      echo " - Be \"localhost\""
      echo " - Be \"conjur\""
      deploy_leader_container
    else
      update_config 'fqdn_loadbalancer' $fqdn_loadbalancer
      echo "Creating local folders."
      mkdir -p $config_dir/{security,configuration,backup,seeds,logs}
      echo "Creating Conjur Docker network."
      docker network create conjur &> /dev/null
      echo "Starting container."
      leader_container_id=$(docker container run \
      --name $fqdn_loadbalancer \
      --detach \
      --network conjur \
      --restart=unless-stopped \
      --security-opt seccomp=unconfined \
      --publish "443:443" \
      --publish "444:444" \
      --publish "5432:5432" \
      --publish "1999:1999" \
      --volume $config_dir/configuration:/opt/cyberark/dap/configuration:Z \
      --volume $config_dir/security:/opt/cyberark/dap/security:Z \
      --volume $config_dir/backup:/opt/conjur/backup:Z \
      --volume $config_dir/seeds:/opt/cyberark/dap/seeds:Z \
      --volume $config_dir/logs:/var/log/conjur:Z \
      $conjur_image)
      update_config 'leader_container_id' $leader_container_id
      echo "Leader/Standby Container deployed!"
    fi
}

#Configure Conjur Enterprise Leader container as leader.
configure_leader_container(){
  echo "Checking to make sure container is currently running."
  if docker container inspect $leader_container_id &> /dev/null
  then
    echo "Found container $leader_container_id running."
    admin_password=$(generate_strong_password)
    echo ""
    echo -n "Please enter company short name (Spaces are not supported): "
    read company_name
    if [[ $company_name = *" "* ]] || [[ $company_name = localhost ]] || [[ $company_name = conjur ]]
    then
      echo "Company name as "$company_name" is not supported."
      echo "The name can not:"
      echo " - Contain any spaces."
      echo " - Be \"localhost\""
      echo " - Be \"conjur\""
      configure_leader_container
    else
      update_config 'company_name' $company_name
      echo "Configuring Conjur Leader container using company name: $company_name"
      docker exec $leader_container_id evoke configure master --accept-eula --hostname $fqdn_loadbalancer --admin-password $admin_password $company_name
      echo "Checking to make sure container has come up successfully"
      if $(curl -ikL --output /dev/null --silent --head --fail https://localhost/health)
      then
        echo "Conjur Leader successfully configured!!!"
        echo "|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
        echo "Admin Password is: $admin_password"
        echo "|||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||||"
      else
        echo "Something went wrong with the leader configuration."
      fi
    fi
  else
    echo "Couldn't find container $leader_container_id running. Please stand up a leader/standby container from the main menu."
  fi
}

generate_strong_password(){
  pass_part_1=$(LC_ALL=C < /dev/urandom tr -dc 'A-Za-z0-9_!@#$%^&*()\-+=' | head -c${1:-16})
  pass_part_2=$(LC_ALL=C < /dev/urandom tr -dc 'A-Za-z0-9_!@#$%^&*()\-+=' | head -c${1:-16})
  pass_part_3=$(LC_ALL=C < /dev/urandom tr -dc 'A-Za-z0-9_!@#$%^&*()\-+=' | head -c${1:-16})
  pass="$pass_part_1"+"$pass_part_2"+"$pass_part_3"
  echo "$pass"
}

#remove containers that have been configured
remove_container(){
  echo "Removing leader container."
  docker container rm -f $leader_container_id &> /dev/null
  echo "Removing CLI container."
  docker container rm -f $cli_container_id &> /dev/null
  echo "Removing docker network."
  docker network rm conjur &> /dev/null
  delete_config
}

poc_configure(){
#create CLI container
  if [ -z $admin_password ]
  then
    echo -n "Enter your admin password: "
    read -s admin_password
    echo ""
    poc_configure;
  else
    echo "Standing up the CLI container."
    cli_container_id=$(docker container run -d --name conjur-cli --network conjur --restart=unless-stopped -v $(pwd)/policy:/policy --entrypoint "" $cli_image sleep infinity)
    update_config 'cli_container_id' $cli_container_id
    #Init conjur session from CLI container

    echo "Configuring CLI container to talk to leader."
    docker exec -i $cli_container_id conjur init --account $company_name --url https://$fqdn_loadbalancer <<< yes &> /dev/null

    #Login to conjur and load policy
    echo "Logging into leader as admin."
    docker exec $cli_container_id conjur authn login -u admin -p $admin_password
    echo "Loading root policy."
    root_policy_output=$(docker exec $cli_container_id conjur policy load --replace root /policy/root.yml)
    echo "Loading app policy."
    app_policy_output=$(docker exec $cli_container_id conjur policy load apps /policy/apps.yml)
    echo "loading secrets policy."
    secrets_policy_output=$(docker exec $cli_container_id conjur policy load apps/secrets /policy/secrets.yml)
    echo "Here are the users that were created:"
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
  fi
}

config_check