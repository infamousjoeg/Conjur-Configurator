#Conjur POC Install - Master install and base policies 
#Please verify the commands ran before running this script in your environment

master_name=fqdn
company_name=Company_Account_Name
admin_password=CyberArk123!

#initiate conjur install

install_conjur(){

#Load the Conjur container. Place conjur-appliance-version.tar.gz in the same folder as this script
tarname=$(find conjur-app*)
conjur_image=$(docker load -i $tarname)
conjur_image=$(echo $conjur_image | sed 's/Loaded image: //')

#create docker network
docker network create conjur

#start docker master container named "conjur-master"
docker container run -d --name $master_name --network conjur --restart=always --security-opt=seccomp:unconfined -p 443:443 -p 5432:5432 -p 1999:1999 $conjur_image

#creates company namespace and configures conjur for secrets storage
docker exec $master_name evoke configure master --accept-eula --hostname $master_name --admin-password $admin_password $company_name

#configure conjur policy and load variables
configure_conjur
}

configure_conjur(){
#create CLI container
docker container run -d --name conjur-cli --network conjur --restart=always --entrypoint "" cyberark/conjur-cli:5 sleep infinity

#set the company name in the cli-retrieve-password.sh script
sed -i "s/master_name=.*/master_name=$master_name/g" policy/cli-retrieve-password.sh
sed -i "s/company_name=.*/company_name=$company_name/g" policy/cli-retrieve-password.sh

#copy policy into container 
docker cp policy/ conjur-cli:/

#Init conjur session from CLI container
docker exec -i conjur-cli conjur init --account $company_name --url https://$master_name <<< yes

#Login to conjur and load policy
docker exec conjur-cli conjur authn login -u admin -p $admin_password
docker exec conjur-cli conjur policy load --replace root /policy/root.yml
docker exec conjur-cli conjur policy load apps /policy/apps.yml
docker exec conjur-cli conjur policy load apps/secrets /policy/secrets.yml

#set values for passwords in secrets policy

docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/ansible_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/electric_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/openshift_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/docker_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/aws_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/azure_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/kubernetes_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/ci-variables/puppet_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/ci-variables/chef_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
docker exec conjur-cli conjur variable values add apps/secrets/ci-variables/jenkins_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
}

install_conjur