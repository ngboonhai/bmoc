# OS Version: Ubuntu 20.04
## Install Docker Engine on SUT
- sudo apt-get update
- sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release
- curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
- echo \
  "deb [arch=amd64 signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
- sudo apt-get update
- sudo apt-get install -y docker-ce docker-ce-cli containerd.io

## Configure Proxies to Docker Enviroment on system
sudo mkdir /etc/systemd/system/docker.service.d
sudo touch /etc/systemd/system/docker.service.d/proxy.conf

echo "[Service]" >> /etc/systemd/system/docker.service.d/proxy.conf
echo 'Environment="http_proxy=http://proxy-dmz.intel.com:911/"' >> /etc/systemd/system/docker.service.d/proxy.conf
echo 'Environment="https_proxy=http://proxy-dmz.intel.com:912/"' >> /etc/systemd/system/docker.service.d/proxy.conf
 
sudo systemctl daemon-reload
sudo systemctl restart docker

##  Set DNS to Docker Engine 
- run below command below command lines to create daemon.json file for DNS configured
sudo touch /etc/docker/daemon.json
ehco '{' >> /etc/docker/daemon.json \
echo '    "dns" : [ "10.248.2.1","10.223.45.36" ]' >> /etc/docker/daemon.json \
echo '}' >> /etc/docker/daemon.json

## Restart docker services on Docker host
sudo service docker restart
