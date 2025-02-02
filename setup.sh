#!/bin/bash
#Conjur POC Install - Master install and base policies 

#variables
config_dir="$HOME/.config/cybr"
config_filename="conjurinstaller.config"
config_filepath="$config_dir/$config_filename"

#This function will check for the existence of a previous configuration file.
config_check(){
  if [ -a $config_filepath ];
  then
    import_menu
  else
    create_config
    function_menu
  fi
}

#This menu will be triggered if a configuration file is found on the system. It gives you an option for importing of the file. 
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

#Main menu with all of the options.
function_menu(){
    until [ "$selection" = "0" ]; do
      clear;
      echo "Welcome to the Conjur Standup Utility! (CSU)"
      echo "This program can help you configure many different types of Conjur instances."
      echo ""
      echo "    	1  -  Deploy Conjur instance container. (Leader/Standby/Follower)"
      echo "    	2  -  Configure Conjur container as Leader."
      echo "    	3  -  Deploy and configure Conjur CLI container."
      echo "    	4  -  Configure POC Policies for Conjur."
      echo "    	5  -  Create seed package for Conjur Follower."
      echo "    	6  -  Create seed package for Conjur Standby."
      echo "    	7  -  Create K8s follower and applications manifest."
      echo "    	8  -  Enable JWT for Jenkins."
      echo "    	9  -  Enable JWT for Gitlab."
      echo "    	A  -  Remove Conjur containers and configuration files."
      echo "    	0  -  Exit"
      echo ""
      echo -n "  Enter selection: "
      read selection
      echo ""
      case $selection in
        1 ) clear ; create_config ; container_runtime ; press_enter ; deploy_leader_container_menu ; press_enter ;;
        2 ) clear ; loadbalancer_leader_exists ; configure_leader_container ; press_enter ;;
        3 ) clear ; cli_configure_menu ; press_enter ;;
        4 ) clear ; policy_load_rest ; press_enter ;;
        5 ) clear ; create_follower_seed ; press_enter ;;
        6 ) clear ; create_standby_seed ; press_enter ;;
        7 ) clear ; create_k8s_yaml ; press_enter ;;
        8 ) clear ; jenkins_jwt ; press_enter ;;
        9 ) clear ; gitlab_jwt ; press_enter ;;
        A ) clear ; remove_container ; press_enter ;;
        0 ) clear ; exit ;;
        * ) clear ; incorrect_selection ; press_enter ;;
      esac
    done
}

#Menu for deciding how to pull the leader image.
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
        2 ) clear ; private_registry "conjur_ent" ; press_enter ; deploy_leader_container ; press_enter ; function_menu ;;
        3 ) clear ; local_registry "conjur_ent" ; deploy_leader_container ; press_enter ; function_menu ;;
        4 ) clear ; import_registry "conjur_ent" ; deploy_leader_container ; press_enter ; function_menu ;;
        5 ) clear ; function_menu ;;
        0 ) clear ; exit ;;
        * ) clear ; incorrect_selection ; press_enter ;;
      esac
    done
}

cli_configure_menu(){
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
        1 ) clear ; pull_dockerhub "cli" ; press_enter ; cli_configure ; press_enter ; function_menu ;;
        2 ) clear ; private_registry "cli" ; press_enter ; cli_configure ; press_enter ; function_menu ;;
        3 ) clear ; local_registry "cli" ; press_enter ; cli_configure ; press_enter ; function_menu ;;
        4 ) clear ; import_registry "cli" ; press_enter ; cli_configure ; press_enter ; function_menu ;;
        5 ) clear ; function_menu ;;
        0 ) clear ; exit ;;
        * ) clear ; incorrect_selection ; press_enter ;;
      esac
    done
}

#Separate different functions to keep information on the screen if needed. 
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

#Function to import the configuration file. Does checking on the contents to make sure it's formatted correctly. Will remove old file if something is wrong. 
import_config(){
  local count=$(wc -l < $config_filepath)
  if [ $count -eq 11 ]
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

#Function to delete the old config file but print the contents first. Just in case they are needed in the future.
delete_config(){
  echo "Contents of old configuration file:"
  echo "$(cat $config_filepath)"
  echo ""
  echo "Deleting configuration file in $config_filepath."
  echo "Deleting previous certificate."
  rm -f $config_dir/conjur-$company_name.pem
  echo "Removing in memory variables."
  conjur_image=
  cli_image=
  fqdn_leader=
  fqdn_follower=
  fqdn_standby=
  fqdn_loadbalancer_leader_standby=
  leader_container_id=
  cli_container_id=
  container_command=
  company_name=
  ssl_cert=
  rm -f $config_filepath
}

#Function to create a configuration file.
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
fqdn_leader=
fqdn_follower=
fqdn_standby=
fqdn_loadbalancer_leader_standby=
leader_container_id=
cli_container_id=
container_command=
company_name=
ssl_cert=
EOF
fi
}

#Function to update the configuration file based on parameters passed into the function.
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

#Function to create a k8s yaml to deploy a follower to kubernetes
create_k8s_yaml(){
  echo "This option will create a k8s manifest file and output it to the current directory."
  if $(curl -ikL --output /dev/null --silent --head --fail https://localhost/health)
  then
    echo "Leader machine is healthy and available."
    echo ""
    echo -n "What is the namespace name in k8s?: "
    read namespace
    echo -n "What service name do you want to use?: "
    read service_name
    seedfile_dir="/tmp/seedfile"
    ssl_cert=$(sed 's/^/    /' $config_dir/conjur-$company_name.pem)
    conjurfqdn=$(if [ -z $fqdn_loadbalancer_leader_standby ]; then echo $fqdn_leader; else echo $fqdn_loadbalancer_leader_standby; fi)
    cat <<EOF > $PWD/$company_name-k8s.yaml
---
apiVersion: v1
kind: Namespace
metadata:
  name: $namespace

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: conjur-cluster
  namespace: $namespace

---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: conjur-authenticator
rules:
- apiGroups: [""]
  resources: ["pods", "serviceaccounts"]
  verbs: ["get", "list"]
- apiGroups: ["extensions"]
  resources: [ "deployments", "replicasets"]
  verbs: ["get", "list"]
- apiGroups: ["apps"]
  resources: [ "deployments", "statefulsets", "replicasets"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["pods/exec"]
  verbs: ["create", "get"]

---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1
metadata:
  name: conjur-authenticator
subjects:
- kind: ServiceAccount
  name: conjur-cluster
  namespace: $namespace
roleRef:
  kind: ClusterRole
  name: conjur-authenticator
  apiGroup: rbac.authorization.k8s.io

---  
kind: ConfigMap
apiVersion: v1
metadata:
  name: conjur-follower-cm
  namespace: $namespace
data:
  CONJUR_ACCOUNT: $company_name
  CONJUR_LEADER_APPLIANCE_URL: "https://$conjurfqdn"
  CONJUR_SEED_FILE_URL: "https://$conjurfqdn/configuration/$company_name/seed/follower"
  CONJUR_AUTHN_LOGIN: "host/cd/kubernetes/k8s-follower-auto-configuration/cluster1/k8s-follower1"
  SEEDFILE_DIR: "$seedfile_dir"
  FOLLOWER_HOSTNAME: "$service_name"
  AUTHENTICATOR_ID: "cluster1"
  CONJUR_SSL_CERTIFICATE: |
$ssl_cert

---
apiVersion: v1
kind: ConfigMap
metadata:
  name: conjur-connect
  namespace: $namespace
  labels:
    app.kubernetes.io/name: "conjur-connect-configmap"
    app.kubernetes.io/instance: "conjur-default-configmap"
    app.kubernetes.io/part-of: "conjur-config"
    conjur.org/name: "conjur-connect-configmap"
data:
  CONJUR_ACCOUNT: $company_name
  CONJUR_APPLIANCE_URL: "https://$conjurfqdn"
  CONJUR_AUTHN_URL: "https://$conjurfqdn/authn-k8s/cluster1"
  CONJUR_AUTHENTICATOR_ID: "cluster1"
  CONJUR_VERSION: "5"
  CONJUR_SSL_CERTIFICATE: |- 
$ssl_cert

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: conjur-follower
  namespace: $namespace
  labels:
    app: cyberark
spec:
  replicas: 1
  selector:
    matchLabels:
      role: access
  template:
    metadata:
      labels:
        role: access
    spec:
      serviceAccountName: conjur-cluster
      automountServiceAccountToken: false
      volumes:
      - name: seedfile
        emptyDir:
          medium: Memory
      - name: conjur-token
        emptyDir:
          medium: Memory
      initContainers:
      - name: seed-fetcher
        image: cyberark/dap-seedfetcher:latest
        imagePullPolicy: IfNotPresent
        envFrom:
          - configMapRef:
              name: conjur-follower-cm
        env:
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: MY_POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
        volumeMounts:
          - name: seedfile
            mountPath: $seedfile_dir
          - name: conjur-token
            mountPath: /run/conjur
      containers:
      - name: follower
        imagePullPolicy: IfNotPresent
        image: $conjur_image
        command: ["$seedfile_dir/start-follower.sh"]
        env:
          - name: CONJUR_AUTHENTICATORS
            value: "authn-k8s/cluster1"
          - name: SEEDFILE_DIR
            value: $seedfile_dir
          - name: KUBERNETES_SERVICE_HOST
            value: ""
          - name: KUBERNETES_SERVICE_PORT_HTTPS
            value: ""
        ports:
          - containerPort: 443
            protocol: TCP
          - containerPort: 5432
            protocol: TCP
          - containerPort: 1999
            protocol: TCP
        readinessProbe:
          httpGet:
            path: /health
            port: 443
            scheme: HTTPS
          initialDelaySeconds: 15
          timeoutSeconds: 5
        volumeMounts:
          - name: seedfile
            mountPath: $seedfile_dir
            readOnly: true
        resources:
          requests:
            memory: "1Gi"
            cpu: "250m"
          limits:
            memory: "2Gi"
            cpu: "500m"
            
---
apiVersion: v1
kind: Service
metadata:
  name: $service_name
  namespace: $namespace
spec:
  ports:
  - name: https
    port: 443
    targetPort: 443
  selector:
    role: access
  type: ClusterIP

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: go-app-account
  namespace: $namespace

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: api-app1
  namespace: $namespace
  labels:
    app: go
spec:
  replicas: 1
  selector:
    matchLabels:
      role: demo
      app: go
  template:
    metadata:
      labels:
        role: demo
        app: go
    spec:
      serviceAccountName: go-app-account
      containers:
      - name: authenticator
        image: cyberark/conjur-authn-k8s-client
        imagePullPolicy: IfNotPresent
        envFrom:
          - configMapRef:
              name: conjur-connect
        env:
          - name: CONJUR_AUTHN_LOGIN
            value: "host/cd/kubernetes/dev-team-1/applications/api-app1"
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: MY_POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
        volumeMounts:
          - mountPath: /run/conjur
            name: conjur-access-token
      - name: goapp
        image: captainfluffytoes/go_app:evan
        imagePullPolicy: IfNotPresent
        envFrom:
          - configMapRef:
              name: conjur-connect
        env:
          - name: CONJUR_AUTHN_TOKEN_FILE
            value: /run/conjur/access-token
          - name: CONJUR_USER_OBJECT
            value: vault1/LOBUser1/Safe2/secret1
          - name: CONJUR_PASS_OBJECT
            value: vault1/LOBUser1/Safe2/secret2
        volumeMounts:
          - mountPath: /run/conjur
            name: conjur-access-token
      volumes:
        - name: conjur-access-token
          emptyDir:
            medium: Memory
---
apiVersion: v1
kind: Secret
metadata:
  name: db-credentials
  namespace: $namespace
type: Opaque
data:
  DBName:   bXlhcHBEQg==
stringData:
  conjur-map: |-   
    username: vault1/LOBUser1/Safe2/secret3
    password: vault1/LOBUser1/Safe2/secret4

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8s-secrets-provider-account
  namespace: $namespace

---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: secrets-access
  namespace: $namespace
rules:
  - apiGroups: [""]
    resources: ["secrets"]
    verbs: [ "get", "update"]

---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  namespace: $namespace
  name: secrets-access-binding
subjects:
  - kind: ServiceAccount
    namespace: $namespace
    name: k8s-secrets-provider-account
roleRef:
  kind: Role
  apiGroup: rbac.authorization.k8s.io
  name: secrets-access

---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: k8s-secrets-app1
  namespace: $namespace
  labels:
    app: k8ssecrets
spec:
  replicas: 1
  selector:
    matchLabels:
      role: demo
      app: k8ssecrets
  template:
    metadata:
      labels:
        role: demo
        app: k8ssecrets
    spec:
      serviceAccountName: k8s-secrets-provider-account
      initContainers:
      - name: k8s-secrets-provider
        image: cyberark/secrets-provider-for-k8s:latest
        imagePullPolicy: IfNotPresent
        envFrom:
          - configMapRef:
              name: conjur-connect
        env:
          - name: MY_POD_NAME
            valueFrom:
              fieldRef:
                fieldPath: metadata.name
          - name: MY_POD_NAMESPACE
            valueFrom:
              fieldRef:
                fieldPath: metadata.namespace
          - name: MY_POD_IP
            valueFrom:
              fieldRef:
                fieldPath: status.podIP
          - name: CONJUR_AUTHN_LOGIN
            value: "host/cd/kubernetes/dev-team-1/applications/k8s-secrets-app1"
          - name: SECRETS_DESTINATION
            value: k8s_secrets
          - name: K8S_SECRETS
            value: db-credentials
      containers:
      - name: k8s-app
        image: centos
        command: ["sleep","infinity"]
        imagePullPolicy: IfNotPresent
        env:
          - name: DB_USERNAME
            valueFrom:
              secretKeyRef:
                name: db-credentials
                key: username
          - name: DB_PASSWORD
            valueFrom:
              secretKeyRef:
                name: db-credentials
                key: password

---
apiVersion: v1
kind: Secret
metadata:
  name: synched-secrets
  namespace: $namespace
type: Opaque
stringData:
  conjur-map: |-   
    username: vault1/LOBUser1/Safe2/secret5
    password: vault1/LOBUser1/Safe2/secret6

---
apiVersion: batch/v1
kind: CronJob
metadata:
  name: secrets-provider
  namespace: $namespace
spec:
  schedule: "* * * * *"
  jobTemplate:
    spec:
      template:
        spec:
          serviceAccountName: k8s-secrets-provider-account
          containers:
          - name: k8s-secrets-provider-namespace
            image: cyberark/secrets-provider-for-k8s:latest
            imagePullPolicy: IfNotPresent
            envFrom:
              - configMapRef:
                  name: conjur-connect
            env:
              - name: MY_POD_NAME
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.name
              - name: MY_POD_NAMESPACE
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.namespace
              - name: MY_POD_IP
                valueFrom:
                  fieldRef:
                    fieldPath: status.podIP
              - name: CONJUR_AUTHN_LOGIN
                value: "host/cd/kubernetes/dev-team-1/applications/k8s-secrets-app2"
              - name: SECRETS_DESTINATION
                value: k8s_secrets
              - name: K8S_SECRETS
                value: synched-secrets
          restartPolicy: OnFailure

---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: k8s-secrets-provider-push-to-file-account
  namespace: $namespace

---
apiVersion: apps/v1
kind: Deployment
metadata:
  labels:
    app: conjur-push-to-file
  name: push-to-file-app1
  namespace: $namespace
spec:
  replicas: 1
  selector:
    matchLabels:
      app: conjur-push-to-file
  template:
    metadata:
      labels:
        app: conjur-push-to-file
      annotations:
        conjur.org/authn-identity: "host/cd/kubernetes/dev-team-1/applications/push-to-file-app1"
        conjur.org/container-mode: sidecar
        conjur.org/secrets-destination: file
        conjur.org/conjur-secrets-policy-path.safe-2: vault1/LOBUser1/Safe2/
        conjur.org/conjur-secrets.safe-2: |
          - username: secret1
          - password: secret2
        conjur.org/secret-file-path.conjur-push-to-file: "./credentials.yaml"
        conjur.org/secret-file-format.conjur-push-to-file: "yaml"
        conjur.org/secrets-refresh-interval: 1m
        conjur.org/secrets-refresh-enabled: "true"
    spec:
      serviceAccountName: k8s-secrets-provider-push-to-file-account
      containers:
      - name: push-to-file-app1
        image: centos:latest
        imagePullPolicy: Always
        command: ["sleep"]
        args: ["infinity"]
        volumeMounts:
          - name: conjur-secrets
            mountPath: /opt/secrets/conjur
            readOnly: true
      - name: push-to-file
        image: 'cyberark/secrets-provider-for-k8s:latest'
        imagePullPolicy: IfNotPresent
        env:
        - name: MY_POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: MY_POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
        envFrom:
        - configMapRef:
            name: conjur-connect
        volumeMounts:
          - name: podinfo
            mountPath: /conjur/podinfo
          - name: conjur-secrets
            mountPath: /conjur/secrets
      volumes:
        - name: podinfo
          downwardAPI:
            items:
              - path: "annotations"
                fieldRef:
                  fieldPath: metadata.annotations
        - name: conjur-secrets
          emptyDir:
            medium: Memory
EOF
    echo "File has been created $PWD/$company_name-k8s.yaml"
    echo "Updating policy with the right namespace value of $namespace."
    if [[ "$OSTYPE" == "linux-gnu"* ]]
    then
      sed -i'' "s~namespace: conjur.*~namespace: $namespace~" ./policy/cd/kubernetes/3-k8s-dev-team-1-apps.yml
      sed -i'' "s~namespace: conjur.*~namespace: $namespace~" ./policy/cd/kubernetes/5-k8s-dev-team-2-apps.yml
      sed -i'' "s~namespace: conjur.*~namespace: $namespace~" ./policy/cd/kubernetes/7-k8s-dev-team-3-apps.yml
      sed -i'' "s~namespace: conjur.*~namespace: $namespace~" ./policy/cd/kubernetes/1-k8s-follower-auto-configuration.yml
    elif [[ "$OSTYPE" == "darwin"* ]]
    then
      sed -i '' "s~namespace: conjur.*~namespace: $namespace~" ./policy/cd/kubernetes/3-k8s-dev-team-1-apps.yml
      sed -i '' "s~namespace: conjur.*~namespace: $namespace~" ./policy/cd/kubernetes/5-k8s-dev-team-2-apps.yml
      sed -i '' "s~namespace: conjur.*~namespace: $namespace~" ./policy/cd/kubernetes/7-k8s-dev-team-3-apps.yml
      sed -i '' "s~namespace: conjur.*~namespace: $namespace~" ./policy/cd/kubernetes/1-k8s-follower-auto-configuration.yml
    else
      echo "Unknown OS for using sed command. Configuration fill will not be updated!" 
    fi
    admin_pass
    api_key=$(curl -k -s -X GET -u admin:$admin_password https://localhost/authn/$company_name/login)
    auth_token=$(curl -k -s --header "Accept-Encoding: base64" -X POST --data $api_key https://localhost/authn/$company_name/admin/authenticate)
    echo "Loading Kubernetes policies."
    authn_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/authenticators/authn-k8s.yml)" https://localhost/policies/$company_name/policy/root)
    seed_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/authenticators/k8s-seed-fetcher.yml)" https://localhost/policies/$company_name/policy/root)
    follower_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/cd/kubernetes/1-k8s-follower-auto-configuration.yml)" https://localhost/policies/$company_name/policy/root)
    k8s_dev_team_1_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/cd/kubernetes/2-k8s-dev-team-1.yml)" https://localhost/policies/$company_name/policy/root)
    k8s_dev_team_1_apps_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/cd/kubernetes/3-k8s-dev-team-1-apps.yml)" https://localhost/policies/$company_name/policy/root)
    k8s_dev_team_2_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/cd/kubernetes/4-k8s-dev-team-2.yml)" https://localhost/policies/$company_name/policy/root)
    k8s_dev_team_2_apps_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/cd/kubernetes/5-k8s-dev-team-2-apps.yml)" https://localhost/policies/$company_name/policy/root)
    k8s_dev_team_3_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/cd/kubernetes/6-k8s-dev-team-3.yml)" https://localhost/policies/$company_name/policy/root)
    k8s_dev_team_3_apps_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/cd/kubernetes/7-k8s-dev-team-3-apps.yml)" https://localhost/policies/$company_name/policy/root)
    k8sgrants_policy=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/cd/kubernetes/8-k8s-grants.yml)" https://localhost/policies/$company_name/policy/root)
    echo ""
    echo "Setting internal CA and Key:"
    $container_command exec $leader_container_id bash -c "openssl genrsa -out ca.key 2048" &> /dev/null
    $container_command exec $leader_container_id bash -c "openssl genrsa -out ca2.key 2048" &> /dev/null
    CONFIG="
[ req ]
distinguished_name = dn
x509_extensions = v3_ca
[ dn ]
[ v3_ca ]
basicConstraints = critical,CA:TRUE
subjectKeyIdentifier   = hash
authorityKeyIdentifier = keyid:always,issuer:always
"
    $container_command exec $leader_container_id bash -c "openssl req -x509 -new -nodes -key ca.key -sha1 -days 3650 -set_serial 0x0 -out ca.cert -subj "/CN=conjur.authn-k8s.cluster1/OU=Conjur Kubernetes CA/O=$company_name" -config <(echo "$CONFIG")" &> /dev/null
    $container_command exec $leader_container_id bash -c "openssl req -x509 -new -nodes -key ca2.key -sha1 -days 3650 -set_serial 0x0 -out ca2.cert -subj "/CN=conjur.authn-k8s.cluster2/OU=Conjur Kubernetes CA/O=$company_name" -config <(echo "$CONFIG")" &> /dev/null    
    api_key=$(curl -k -s -X GET -u admin:$admin_password https://localhost/authn/$company_name/login)
    auth_token=$(curl -k -s --header "Accept-Encoding: base64" -X POST --data $api_key https://localhost/authn/$company_name/admin/authenticate)
    curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$($container_command exec $leader_container_id bash -c "cat ca.key")" https://localhost/secrets/$company_name/variable/conjur/authn-k8s/cluster1/ca/key
    curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$($container_command exec $leader_container_id bash -c "cat ca.cert")" https://localhost/secrets/$company_name/variable/conjur/authn-k8s/cluster1/ca/cert
    curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$($container_command exec $leader_container_id bash -c "cat ca2.key")" https://localhost/secrets/$company_name/variable/conjur/authn-k8s/cluster2/ca/key
    curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$($container_command exec $leader_container_id bash -c "cat ca2.cert")" https://localhost/secrets/$company_name/variable/conjur/authn-k8s/cluster2/ca/cert
    echo "----------Instructions----------"
    echo "Manifest file needs to be loaded into the cluser with <kubectl apply -f $company_name-k8s.yaml>."
    echo "The certificate in the conjur-connect config map needs to be updated with the follower certificate. The initial cert loaded into the config map is that of the leader. If connecting to the leader is desirned then change all of the url addresses to the leader fqdn and re-apply the manifest."
    echo ""
    echo "Once loaded, there are 3 variables in conjur that need information:"
    echo ""
    echo "conjur/authn-k8s/cluster1/kubernetes/api-url needs to have the api url so that the leader can communicate with the cluster's API."
    echo "conjur/authn-k8s/cluster1/kubernetes/ca-cert needs to have the cluster cert so that the leader can send encrypted communication to the cluster's API."
    echo "conjur/authn-k8s/cluster1/kubernetes/service-account-token needs to have a valid token from the conjur-cluster service account."
    echo "----------End----------"
    echo ""
  else
    echo "Leader not reporting as healthy. Is the leader running on this machine?"
    echo "Returning to main menu."
    press_enter
    function_menu;
  fi
}

jenkins_jwt(){
  echo "This option enables jwt authentication for Jenkins"
  echo -n "Please enter the hostname of your Jenkins instance (in the format https://jenkins.com): "
  read jenkins_hostname
  echo "Loading Jenkins policy and values."
  admin_pass
  api_key=$(curl -k -s -X GET -u admin:$admin_password https://localhost/authn/$company_name/login)
  auth_token=$(curl -k -s --header "Accept-Encoding: base64" -X POST --data $api_key https://localhost/authn/$company_name/admin/authenticate)
  echo "Loading authentication policy."
  jenkins_policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/authenticators/authn-jwt-jenkins.yml)" https://localhost/policies/$company_name/policy/root)
  echo $jenkins_policy_output
  echo "Loading Dev_Team_1 policy."
  dev_team1__policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/ci/jenkins/1-jenkins-dev-team-1.yml)" https://localhost/policies/$company_name/policy/root)
  echo $dev_team1__policy_output
  echo "Loading Dev_Team_2 policy."
  dev_team2__policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/ci/jenkins/2-jenkins-dev-team-2.yml)" https://localhost/policies/$company_name/policy/root)
  echo $dev_team2__policy_output
  echo "Loading jenkins projects policy."
  jenkins_projects__policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/ci/jenkins/3-jenkins-projects.yml)" https://localhost/policies/$company_name/policy/root)
  echo $jenkins_projects__policy_output
  echo "Loading jenkins grants policy."
  jenkins_grants__policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/ci/jenkins/4-jenkins-grants.yml)" https://localhost/policies/$company_name/policy/root)
  echo $jenkins_grants__policy_output
  echo "Loading JWKS value."
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$jenkins_hostname/jwtauth/conjur-jwk-set" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/jenkins1/jwks-uri
  echo "Loading identity path"
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "/ci/jenkins/projects" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/jenkins1/identity-path
  echo "Loading issuer"
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$jenkins_hostname" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/jenkins1/issuer
  echo "Loading token app property"
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "jenkins_full_name" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/jenkins1/token-app-property
  echo "Loading audience"
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "https://$(if [ -z $fqdn_loadbalancer_leader_standby ]; then echo $fqdn_leader; else echo $fqdn_loadbalancer_leader_standby; fi)" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/jenkins1/audience
  echo ""
  echo "----------Instructions----------"
  echo "Please fill in the Jenkins plugin configuration with this information:"
  echo "Conjur Appliance"
  echo "Account - $company_name"
  echo "Appliance URL - https://$(if [ -z $fqdn_loadbalancer_leader_standby ]; then echo $fqdn_leader; else echo $fqdn_loadbalancer_leader_standby; fi)"
  echo "Conjur Auth Credential - Leave Blank"
  echo "Conjur SSL Certificate - Import Cert directly into Jenkins keystore"
  echo ""
  echo "Conjur JWT Authentication"
  echo "Enable JWT Key Set endpoint? - checked"
  echo "Auth WebServiceID - authn-jwt/jenkins1"
  echo "JWT Audience - https://$(if [ -z $fqdn_loadbalancer_leader_standby ]; then echo $fqdn_leader; else echo $fqdn_loadbalancer_leader_standby; fi)"
  echo "Signing Key Lifetime In Minutes - 5"
  echo "JWT Token Duration In Seconds - 60"
  echo "Enable Context Aware Credential Stores? - checked"
  echo "Identity Field Name - conjur_host"
  echo "Identity Format Fields - jenkins_name"
  echo "Identity Fields Separator - \"-\""
  echo ""
  echo "Create a folder with the name - Dev-Team-1"
  echo "Create a folder with the name - Dev-team-2"
  echo "Create Pipeline Jobs within each folder called - Job1 and Job2"
  echo "----------End----------"
}

gitlab_jwt(){
  echo "This option enables jwt authentication for Gitlab"
  echo -n "Please enter the hostname of your Gitlab instance (in the format https://gitlab.com): "
  read gitlab_hostname
  echo "Loading Gitlab policies and values"
  admin_pass
  api_key=$(curl -k -s -X GET -u admin:$admin_password https://localhost/authn/$company_name/login)
  auth_token=$(curl -k -s --header "Accept-Encoding: base64" -X POST --data $api_key https://localhost/authn/$company_name/admin/authenticate)
  echo "Loading authentication policy."
  gitlab_policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/authenticators/authn-jwt-gitlab.yml)" https://localhost/policies/$company_name/policy/root)
  echo $gitlab_policy_output
  echo "Loading Dev_Team_1 policy."
  dev_team1__policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/ci/gitlab/1-gitlab-dev-team-1.yml)" https://localhost/policies/$company_name/policy/root)
  echo $dev_team1__policy_output
  echo "Loading Dev_Team_1 policy."
  dev_team2__policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/ci/gitlab/2-gitlab-dev-team-2.yml)" https://localhost/policies/$company_name/policy/root)
  echo $dev_team2__policy_output
  echo "Loading jenkins projects policy."
  gitlab_projects__policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/ci/gitlab/3-gitlab-projects.yml)" https://localhost/policies/$company_name/policy/root)
  echo $gitlab_projects__policy_output
  echo "Loading jenkins grants policy."
  gitlab_grants__policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/ci/gitlab/4-gitlab-grants.yml)" https://localhost/policies/$company_name/policy/root)
  echo $gitlab_grants__policy_output
  echo "Loading JWKS value."
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$gitlab_hostname/-/jwks/" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/gitlab1/jwks-uri
  echo "Loading identity path"
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "/ci/gitlab/projectsr" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/gitlab1/identity-path
  echo "Loading issuer"
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$gitlab_hostname" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/gitlab1/issuer
  echo "Loading token app property"
  curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "project_path" https://localhost/secrets/$company_name/variable/conjur/authn-jwt/gitlab1/token-app-property
  echo ""
  echo "----------Instructions----------"
  echo "Please create two groups in Gitlab - Dev-Team-1 and Dev-Team-2"
  echo "Please then create two repositories - Dev-Team-1/Job1 and Dev-Team-2/Job2"
  echo "Save bash.gitlab-ci.yml to the root of the each repository."
  echo "Exporting bash.gitlab-ci.yml to this $PWD/bash.gitlab-ci.yml."
  conjur_address=$(if [ -z $fqdn_loadbalancer_leader_standby ]; then echo $fqdn_leader; else echo $fqdn_loadbalancer_leader_standby; fi)
  cat <<EOF > $PWD/bash.gitlab-ci.yml
image: ubuntu:latest
test1:
  stage: test
  script:
    - echo "Authenticating to Conjur"
    - TOKEN=\$(curl -k --request POST 'https://$conjur_address/authn-jwt/gitlab1/$company_name/authenticate' --header 'Content-Type:application/x-www-form-urlencoded' --header "Accept-Encoding:base64" --data-urlencode "jwt=$CI_JOB_JWT")
    - echo "Here is the access token:"
    - echo \$TOKEN
    - echo ""
    - echo "Fetching secret"
    - SECRET=\$(curl -k --header "Authorization:Token token=\"$TOKEN\"" -X GET https://$conjur_address/resources/$company_name?kind=variable)
    - echo "Here is the list of secrets you can access:"
    - echo $SECRET
EOF
  echo "----------End----------"
}

admin_pass(){
  if [ -z $admin_password ]
  then
    echo -n "Enter your admin password: "
    read -s admin_password
    echo ""
    output=$(curl -sIk -o /dev/null -w "%{http_code}" --user admin:$admin_password https://localhost/authn/cyberark/login)
    if $(echo $output | grep "200" > /dev/null)
    then
      echo "Verified that the admin password is correct."
      press_enter
    else
      echo "Admin password is incorrect. Press Enter to try again."
      unset admin_password
      press_enter
      admin_pass
    fi
  fi
}

#Function to create a follower seed file in the current directory for use by another conjur instance. The seed file will need to be copied to the other instance/machine.
create_follower_seed(){
  echo "Checking to see if Master is configured"
  echo -n "Enter follower DNS name (or follower loadbalancer name): "
  read fqdn_follower
  update_config 'fqdn_follower' $fqdn_follower
  $container_command exec $leader_container_id evoke seed follower $fqdn_follower > follower_seed.tar
  echo "Seed file exported at $PWD/follower_seed.tar."
  echo "Please transport that file over to the follower instance."
}

#Function to create a standby seed file in the current directory for use by another conjur instance. The seed file will need to be copied to the other instance/machine.
create_standby_seed(){
  echo "Checking to see if Master is configured"
  echo -n "Enter standby DNS name: "
  read fqdn_standby
  update_config 'fqdn_standby' $fqdn_standby
  $container_command exec $leader_container_id evoke seed standby $fqdn_standby > standby_seed.tar
  echo "Seed file exported at $PWD/standby_seed.tar."
  echo "Please transport that file over to the standby instance."
}

#check if Podman or Docker
container_runtime(){
  if command -v podman &> /dev/null
  then
    echo "PodMan has been found."
    container_command="podman"
    update_config 'container_command' $container_command
  elif command -v docker &> /dev/null
  then
    echo "Docker has been found."
    container_command="docker"
    update_config 'container_command' $container_command
    docker_check
  else
    echo "No Runtime found."
    echo "Returning to main menu."
    press_enter;
    function_menu;
  fi
}

#Check the installation of Docker for known issues. 
docker_check(){
  echo "Checking if the daemon is accessible"
    if ! $container_command info >/dev/null 2>&1; 
    then
      echo "Docker daemon doesn't appear to be running or is inaccessible."
      echo "Returning to main menu."
      press_enter;
      function_menu;
    else
      echo "Docker daemon appears to be running."
    fi
  echo "Checking if d_type true"
    if ! $container_command system info | grep "Supports d_type: true" >/dev/null 2>&1; 
    then
      echo "Docker d_type isn't enabled."
      echo "Returning to main menu."
      press_enter;
      function_menu;
    else
      echo "d_type is true for Docker."
    fi
  echo "All docker checks have passed."
}

#Function to pull image directly from docker hub. Defaults to using a public image. NOT OFFICIAL.
pull_dockerhub(){
  if curl -Is https://hub.docker.com | head -n 1 | grep "200" &> /dev/null
  then
    echo "Can connect to dockerhub and will pull image directly"
        if [ $1 = "conjur_ent" ]
        then
          echo -n "What is the repo and image name to be pulled?: "
          read dockerhub_conjur_image
          conjur_image=$dockerhub_conjur_image
          echo "Pulling image: $conjur_image"
          $container_command pull $conjur_image &> /dev/null
          update_config 'conjur_image' $conjur_image
        elif [ $1 = "cli" ]
        then
          cli_image=cyberark/conjur-cli:5-latest
          echo "Pulling image: $cli_image"
          $container_command pull $cli_image &> /dev/null
          update_config 'cli_image' $cli_image
        fi
  else
    echo "Can't connect to dockerhub."
    echo "Returning to previous menu."
    press_enter
    ${FUNCNAME[1]};
  fi
}

#Function that will use a provate registry. You will need to provide the image name from a local registry. 
private_registry(){
  echo -n "Enter the image name (Use format registryAddress/imageName:ImageTag): "
  read image
  if ! $container_command pull $image
  then
    echo "Couldn't pull image from registry. Please verify network connection and/or verify that docker is properly authenticated."
    press_enter;
    ${FUNCNAME[1]};
  else
    echo "Connection to registry successful!"
    echo "Pulling image."
    $container_command pull $image &> /dev/null
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

#Function to pull something from the local registry. You will need to know the image name. 
local_registry(){
  echo -n "Enter the image name (Use format registryAddress/imageName:ImageTag): "
  read image
  if [ "$($container_command images --filter "reference=$image")" = "" ]
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
  echo "Scanning current directory for saved image file with the name of conjur-appliance."
  if [ $(find conjur-app*) &> /dev/null ] && [ $1 = "conjur_ent" ]
  then
    echo "Found local appliance file."
    tarname=$(find conjur-app*)
    conjur_image=$($container_command load -i $tarname)
    conjur_image=$(echo $conjur_image | sed 's/Loaded image: //')
    update_config 'conjur_image' $conjur_image
  elif [ $(find conjur-cli*) &> /dev/null ] && [ $1 = "cli" ]
  then
    echo "Found local cli file."
    tarname=$(find conjur-cli*)
    cli_image=$($container_command load -i $tarname)
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
    echo -n "Enter the DNS name for the Conjur leader (Name can not be \"localhost\" or \"conjur\" or contain any spaces): "
    read fqdn_leader
    if [[ $fqdn_leader = *" "* ]] || [[ $fqdn_leader = localhost ]] || [[ $fqdn_leader = conjur ]] || [[ $fqdn_leader = "" ]]
    then
      echo "Load balancer DNS name as "$fqdn_leader" is not supported."
      echo "The name can not:"
      echo " - Contain any spaces."
      echo " - Be \"localhost\""
      echo " - Be \"conjur\""
      echo " - Be blank."
      press_enter
      deploy_leader_container
    else
      update_config 'fqdn_leader' $fqdn_leader
      echo "Creating local folders."
      mkdir -p $config_dir/{security,configuration,backup,seeds,logs}
      cat <<EOF > $config_dir/conjur.yml
#List of authenticators enabled for this node
authenticators: 
  - authn-k8s/cluster1
  - authn-iam/prod
  - authn-azure/prod
  - authn-oidc/provider
  - authn-jwt/jenkins1
  - authn-jwt/gitlab1
  - authn
EOF
      echo "Creating Conjur $container_command network."
      $container_command network create conjur &> /dev/null
      echo "Starting container."
      leader_container_id=$($container_command container run \
      --name $fqdn_leader \
      --detach \
      --network conjur \
      --restart=unless-stopped \
      --security-opt seccomp=unconfined \
      --publish "443:443" \
      --publish "444:444" \
      --publish "5432:5432" \
      --publish "1999:1999" \
      --volume $config_dir/conjur.yml:/etc/conjur/config/conjur.yml:Z \
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

loadbalancer_leader_exists(){
  echo -n "Will there be a loadbalancer used for the leader and standby instance? (y or n): "
  read loadbalancer_exists
  if [[ $loadbalancer_exists = "y" ]]
  then
    echo -n "What is the DNS name of the loadbalancer for the leader/standby instances?: "
    read fqdn_loadbalancer_leader_standby
    if [[ $fqdn_loadbalancer_leader_standby = *" "* ]] || [[ $fqdn_loadbalancer_leader_standby = localhost ]] || [[ $fqdn_loadbalancer_leader_standby = conjur ]] || [[ $fqdn_loadbalancer_leader_standby = "" ]]
    then
      echo "Load balancer DNS name as "$fqdn_loadbalancer_leader_standby" is not supported."
      echo "The name can not:"
      echo " - Contain any spaces."
      echo " - Be \"localhost\"."
      echo " - Be \"conjur\"."
      echo " - Be blank."
      press_enter
      loadbalancer_leader_exists
    else
      update_config 'fqdn_loadbalancer_leader_standby' $fqdn_loadbalancer_leader_standby
    fi
  elif [[ $loadbalancer_exists = "n" ]]
  then
    echo "No loadblancer DNS will be configured"
    press_enter
  else
    echo "Incorrect selection. You entered \"$loadbalancer_exists\" and that is not supported"
    echo "Returning to previous menu."
    press_enter
    ${FUNCNAME[1]};
  fi
}

#Configure Conjur Enterprise Leader container as leader.
configure_leader_container(){
  echo "Checking to make sure leader container is currently running."
  if $container_command container ls --filter id=$leader_container_id | grep Up  &> /dev/null
  then
    echo "Found container $leader_container_id running."
    admin_password=$(generate_strong_password)
    echo ""
    echo -n "Please enter company short name (Spaces are not supported): "
    read company_name
    if [[ $company_name = *" "* ]] || [[ $company_name = localhost ]] || [[ $company_name = conjur ]] || [[ $company_name = "" ]]
    then
      echo "Company name as "$company_name" is not supported."
      echo "The name can not:"
      echo " - Contain any spaces."
      echo " - Be \"localhost\"."
      echo " - Be \"conjur\"."
      echo " - Be blank."
      press_enter
      configure_leader_container
    else
      update_config 'company_name' $company_name
      echo ""
      echo "Configuring Conjur Leader container using company name: $company_name"
      if [ -z $fqdn_loadbalancer_leader_standby ];
      then
        $container_command exec $leader_container_id evoke configure master --debug --accept-eula --hostname $fqdn_leader --admin-password $admin_password $company_name
      else
        $container_command exec $leader_container_id evoke configure master --debug --accept-eula --hostname $fqdn_loadbalancer_leader_standby --master-altnames $fqdn_leader --admin-password $admin_password $company_name
      fi
      echo "Checking to make sure container has come up successfully"
      if $(curl -ikL --output /dev/null --silent --head --fail https://localhost/health)
      then
        echo ""
        echo "Exporting certificate to confiuration directory"
        if [ -z $fqdn_loadbalancer_leader_standby ];
        then
          $container_command cp $leader_container_id:/opt/conjur/etc/ssl/$fqdn_leader.pem $config_dir/conjur-$company_name.pem
        else
          $container_command cp $leader_container_id:/opt/conjur/etc/ssl/$fqdn_loadbalancer_leader_standby.pem $config_dir/conjur-$company_name.pem
        fi
        echo "Exported certificate to $config_dir/conjur-$company_name.pem"
        update_config 'ssl_cert' $config_dir/conjur-$company_name.pem
        echo ""
        echo "Setting log level to debug"
        $container_command exec $leader_container_id evoke variable set CONJUR_LOG_LEVEL debug &> /dev/null
        echo ""
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
  $container_command container rm -f $leader_container_id &> /dev/null
  echo "Removing CLI container."
  $container_command container rm -f $cli_container_id &> /dev/null
  echo "Removing docker network."
  $container_command network rm conjur &> /dev/null
  delete_config
}

cli_configure(){
  if [ -z $admin_password ]
  then
    echo -n "Enter your admin password: "
    read -s admin_password
    echo ""
    cli_configure;
  else
    case "$container_command" in
      *podman* ) echo "PodMan networking requires customization to allow the CLI container to work in an automated fashion. Please configure manually if CLI is desired."; echo "returning to main menu."; press_enter; function_menu ;;
      *docker* ) cli_container_id=$($container_command container run -d --name conjur-cli --network conjur --restart=unless-stopped -v $(pwd)/policy:/policy --entrypoint "" $cli_image sleep infinity) ;;
      * ) echo "Error with defining the continer command used on the system. Returning to the main menu." ; press_enter ; function_menu ;;
    esac
    update_config 'cli_container_id' $cli_container_id
    echo "Configuring CLI container to talk to leader."
    $container_command exec -i $cli_container_id conjur init --account $company_name --url https://$fqdn_leader <<< yes &> /dev/null
    echo "Logging into leader as admin."
    $container_command exec $cli_container_id conjur authn login -u admin -p $admin_password
  fi
}

policy_load_rest(){
  admin_pass
  if $(curl -ikL --output /dev/null --silent --head --fail https://localhost/health)
  then
    echo "Getting API KEY"
    api_key=$(curl -k -s -X GET -u admin:$admin_password https://localhost/authn/$company_name/login)
    echo "Getting Auth token"
    auth_token=$(curl -k -s --header "Accept-Encoding: base64" -X POST --data $api_key https://localhost/authn/$company_name/admin/authenticate)
    echo "loading Conjur Admins policy."
    admin_users_policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/root/1-conjur-admins.yml)" https://localhost/policies/$company_name/policy/root)
    echo "loading Conjur auditors policy."
    auditors_users_policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/root/2-conjur-auditors.yml)" https://localhost/policies/$company_name/policy/root)    
    echo "Loading root policy."
    root_policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/root/3-root.yml)" https://localhost/policies/$company_name/policy/root)
    echo "loading secrets policy."
    secrets_policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/root/4-secrets.yml)" https://localhost/policies/$company_name/policy/root)
    echo "loading root permits policy."
    permits_policy_output=$(curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$(cat policy/root/5-root-permits.yml)" https://localhost/policies/$company_name/policy/root)
    echo ""
    echo "Creating dummy secrets"
    for (( count=1; count<=8; count++ ))
    do
      for ((secret_count=1; secret_count<=8; secret_count++))
      do
        secret=$(LC_ALL=C < /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
        echo "Secret vault1/LOBUser1/Safe$count/secret$secret_count is set to $secret"
        curl -k -s --header "Authorization: Token token=\"$auth_token\"" -X POST -d "$secret" https://localhost/secrets/$company_name/variable/vault1/LOBUser1/Safe$count/secret$secret_count
      done
    done
    echo ""
    echo "Here are the admin users that were created:"
    echo $admin_users_policy_output
    echo $admin_users_policy_output > $PWD/admin_users_api.txt
    echo "Created text file with user information at $PWD/admin_users_api.txt"
    echo ""
    echo "Here are the auditor users that were created:"
    echo $auditors_users_policy_output
    echo $aduitors_users_policy_output > $PWD/auditors_users_api.txt
    echo "Created text file with user information at $PWD/auditors_users_api.txt"
  else
    echo "Master is unhealthy"
    echo "Returning to Main Menu."
    press_enter
    function_menu
  fi
}

config_check