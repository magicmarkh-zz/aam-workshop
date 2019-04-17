#Conjur POC Install - Master install and base policies 
#Please verify the commands ran before running this script in your environment

#Global Variables
reset=`tput sgr0`
me=`basename "${0%.sh}"`

#Generic output functions
print_head(){
  local white=`tput setaf 7`
  echo ""
  echo "==========================================================================="
  echo "${white}$1${reset}"
  echo "==========================================================================="
  echo ""
}
print_info(){
  echo "INFO: $1"
  echo "INFO: $1" >> ${me}.log
}
print_success(){
  local green=`tput setaf 2`
  echo "${green}SUCCESS: $1${reset}"
  echo "SUCCESS: $1" >> ${me}.log
}
print_error(){
  local red=`tput setaf 1`
  echo "${red}ERROR: $1${reset}"
  echo "ERROR: $1" >> ${me}.log
}

checkOS(){
print_head "Verifying Operating System"
touch ${me}.log
echo "Log file generated on $(date)" >> ${me}.log
case "$(cat /etc/*-release | grep -w ID_LIKE)" in
  'ID_LIKE="rhel fedora"' )
    print_success "OS is $(cat /etc/*-release | grep -w PRETTY_NAME | sed 's/PRETTY_NAME=//')\n"
    install_yum $(cat /etc/*-release | grep -w PRETTY_NAME | sed 's/PRETTY_NAME=//')
    ;;
  'ID_LIKE="fedora"' )
    print_success "OS is $(cat /etc/*-release | grep -w PRETTY_NAME | sed 's/PRETTY_NAME=//')\n"
    install_yum $(cat /etc/*-release | grep -w PRETTY_NAME | sed 's/PRETTY_NAME=//')
    ;;
  'ID_LIKE=debian' )
    print_success "OS is $(cat /etc/*-release | grep -w PRETTY_NAME | sed 's/PRETTY_NAME=//')\n"
    install_apt $(cat /etc/*-release | grep -w PRETTY_NAME | sed 's/PRETTY_NAME=//')
    ;;
esac
}

install_yum(){
print_head "Installing required packages for $1"
  
#Update OS
print_info "Installing dependencies via yum"
print_info "This may take some time"
sudo yum update -y >> ${me}.log

#Install Docker CE
print_info "Installing pre-requisite packages - this may take some time"
pkgarray=(yum-utils device-mapper-persistent-data lvm2)
for pkg in ${pkgarray[@]}
do
  pkg="$pkg"
  sudo yum list $pkg > /dev/null
  if [[ $? -eq 0 ]]; then 
    print_info "Installing $pkg"
    sudo yum -y install $pkg >> ${me}.log
    sudo yum list installed $pkg > /dev/null
    if [[ $? -eq 0 ]]; then
      print_success "$pkg installed"
    else
      print_error "$pkg could not be installed. Exiting..."
      exit 1
    fi
  else
    print_error "Required package - $pkg - not found. Exiting..."
    exit 1
  fi
done
print_success "Required packages installed."

print_info "Adding Docker Repo"
sudo yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo >> ${me}.log 

print_info "Installing Docker"
sudo yum -y install docker-ce >> ${me}.log
sudo yum list installed docker-ce > /dev/null
if [[ $? -eq 0 ]]; then
print_success "docker-ce installed"
else
print_error "docker-ce could not be installed. Exiting..."
exit 1
fi

#config docker to start automatically and start the service
print_info "Enabling Docker"
sudo systemctl start docker
sudo systemctl enable /usr/lib/systemd/system/docker.service >> ${me}.log 2>&1

#Installing docker compose
sudo curl -L "https://github.com/docker/compose/releases/download/1.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose
sudo ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

#initiate conjur install
install_conjur
}

install_apt(){
print_head "Installing required packages for $1"
print_info "Installing dependencies via apt"

#update OS
sudo apt-get upgrade -y

#Install packages to allow apt to use a repository over HTTPS:
sudo apt-get install apt-transport-https ca-certificates curl software-properties-common -y

#Add Docker’s official GPG key:
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

#Set up stable docker repository
sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

#Install latest version of docker-ce
sudo apt-get install docker-ce -y

#initiate conjur install
install_conjur
}

install_conjur(){
print_head "Installing Conjur"
#Pull new docker images
sudo docker-compose pull

#Generate Conjur OSS data-key and update docker-compose.yml
print_info "Generating Conjur Data Key"
sudo docker-compose run --no-deps --rm conjur data-key generate > data_key
local data_key=$(< data_key)
print_info "Updating docker-compose.yml with Conjur Data Key"
sed -i "s|CONJUR_DATA_KEY:.*|CONJUR_DATA_KEY: $data_key|g" docker-compose.yml
print_info "Conjur Data Key is: $data_key"

#Start containers with docker-compose.yml
print_info "Starting Docker Containers - conjur-master, conjur-cli, database"
sudo docker-compose up -d
print_info "Sleeping for 30 Seconds - Containers initializing" 
sleep 10
print_info "Sleeping for 20 Seconds - Contianers initializing"
sleep 10
print_info "Sleeping for 10 Seconds - Containers initializing"

#Verify conjur containers are running
print_info "Verifying Conjur Master is running"
if [[ "$(docker ps -q -f name=conjur-master)" ]]; then
  print_success "Conjur container is running"
else
  print_error "Conjur is not running. Review docker logs for more info. Exiting..."
  exit 1
fi
print_info "Verifying Conjur CLI is running"
if [[ "$(docker ps -q -f name=conjur-cli)" ]]; then
  print_success "Conjur CLI container is running"
else
  print_error "Conjur CLI is not running. Review docker logs for more info. Exiting..."
  exit 1
fi
print_info "Verifying Conjur Database is running"
if [[ "$(docker ps -q -f name=database)" ]]; then
  print_success "Conjur Database is running"
else
  print_error "Conjur Databaseis not running. Review docker logs for more info. Exiting..."
  exit 1
fi

#configure conjur policy and load variables
configure_conjur
}

configure_conjur(){
print_head "Configuring Conjur"

print_info "Generating Conjur admin key"
sudo docker-compose exec conjur conjurctl account create ws_admin > ws_admin_key
ws_key=$(cat ws_admin_key | awk '/API key for admin: /' | sed 's|API key for admin: ||')
print_info "Admin API key is $ws_key"

#copy policy into container 
sudo docker cp policy/ conjur-cli:/

#Init conjur session from CLI container
sudo docker exec -i conjur-cli conjur init -u conjur-master -a ws_admin

#Login to conjur and load policy
sudo docker exec conjur-cli conjur authn login -u admin -p $ws_key
sudo docker exec conjur-cli conjur policy load --replace root /policy/root.yml
sudo docker exec conjur-cli conjur policy load apps /policy/apps.yml
sudo docker exec conjur-cli conjur policy load apps/secrets /policy/secrets.yml

#set values for passwords in secrets policy

sudo docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/ansible_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/electric_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/openshift_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/docker_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/aws_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/azure_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/cd-variables/kubernetes_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/ci-variables/puppet_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/ci-variables/chef_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
sudo docker exec conjur-cli conjur variable values add apps/secrets/ci-variables/jenkins_secret $(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
}

checkOS
