docker run \
  -p 9090:8080 \
  -d \
  -v /var/run/docker.sock:/var/run/docker.sock \
  --name jenkins \
  jenkins/jenkins:lts

docker exec -u 0 jenkins apt-get update
docker exec -u 0 jenkins apt-get -y install apt-transport-https ca-certificates curl gnupg-agent software-properties-common 
docker exec -u 0 jenkins bash -c 'curl -fsSL https://download.docker.com/linux/$(. /etc/os-release; echo "$ID")/gpg | apt-key add -'
docker exec -u 0 -i jenkins add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/debian \
   stretch \
   stable"
docker exec -u 0 jenkins apt-get update
docker exec -u 0 jenkins apt-get -y install docker-ce

grpNum=$(getent group docker | cut -d: -f3)

docker exec -u 0 jenkins groupmod -g $grpNum docker
docker exec -u 0 jenkins usermod -aG docker jenkins