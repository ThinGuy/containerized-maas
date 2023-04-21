<img width=200 src="https://raw.githubusercontent.com/thinguy/containerized-maas/master/containerized-maas.svg">

# Overview
Provides a [region, rack, or region+rack](https://maas.io/docs/about-controllers) [MAAS](https://maas.io) controller running in a systemd-enabled + snapd docker container.

You can build your own following the directions below or run the demo image from docker hub

**Caveats:**
 - This is a work in progress
 - This requires docker-ce from docker.com, it will NOT work with the [snapped version of docker](https://snapcraft.io/docker)
 - This has not been through formal QA testing
 - This image is not officially supported
 - This runs as a privileged container
 - This is a *Work in Progress*

### Install Docker-CE from Docker.com
```
curl -sSlL https://download.docker.com/linux/ubuntu/gpg|gpg --dearmor|sudo tee 1>/dev/null /etc/apt/trusted.gpg.d/docker-ce.gpg
echo "deb [arch=amd64 signed-by=/etc/apt/trusted.gpg.d/docker-ce.gpg] https://download.docker.com/linux/ubuntu jammy stable"|sudo tee 1>/dev/null /etc/apt/sources.list.d/docker-ce.list
sudo apt update
sudo apt install docker-ce -yqf
sudo groupadd docker
sudo usermod -aG docker $(id -un)
newgrp docker
```

## Run from dockerhub

### Run a region+rack combo

**Note:** *This requires an existing PostgreSQL 14 server configured as per the [MAAS Documentation](https://maas.io/docs/bootstrap-maas)* 

```
export PGCON="postgres://maas:maas@192.168.0.159:5432/maasdb";
export MAAS_DOMAIN=craigbender.me
export MAAS_CONTAINER_NAME=maas
export MAAS_PROFILE=admin
export MAAS_PASS=admin
export MAAS_EMAIL=maas-admin@${MAAS_DOMAIN}
export MAAS_SSH_IMPORT_ID=gh:thinguy
export MAAS_URL="http://localhost:5240/MAAS"

docker run \
  --rm \
  -it \
  --name ${MAAS_CONTAINER_NAME} \
  -h ${MAAS_CONTAINER_NAME}.${MAAS_DOMAIN} \
  -p 5240:5240 \
  --privileged \
  craigbender/cmaas:jammy-3.3 \
  "maas init region+rack --maas-url ${MAAS_URL} --database-uri ${PGCON} --force;maas createadmin --username ${MAAS_PROFILE} --password ${MAAS_PASS} --email ${MAAS_EMAIL} --ssh-import ${MAAS_SSH_IMPORT_ID};maas login ${MAAS_PROFILE} http://localhost:5240/MAAS \$(maas apikey --username ${MAAS_PROFILE});bash"
```

### Run a region

**Note:** *This requires an existing PostgreSQL 14 server configured as per the [MAAS Documentation](https://maas.io/docs/bootstrap-maas)* 

```
export PGCON="postgres://maas:maas@192.168.0.159:5432/maasdb";
export MAAS_DOMAIN=craigbender.me
export MAAS_CONTAINER_NAME=maas-region
export MAAS_PROFILE=admin
export MAAS_PASS=admin
export MAAS_EMAIL=maas-admin@${MAAS_DOMAIN}
export MAAS_SSH_IMPORT_ID=gh:thinguy
export MAAS_URL="http://localhost:5240/MAAS"

docker run \
  --rm \
  -it \
  --name ${MAAS_CONTAINER_NAME} \
  -h ${MAAS_CONTAINER_NAME}.${MAAS_DOMAIN} \
  -p 5240:5240 \
  --privileged \
  craigbender/cmaas:jammy-3.3 \
  "maas init region --maas-url ${MAAS_URL} --database-uri ${PGCON} --force;maas createadmin --username ${MAAS_PROFILE} --password ${MAAS_PASS} --email ${MAAS_EMAIL} --ssh-import ${MAAS_SSH_IMPORT_ID};maas login ${MAAS_PROFILE} http://localhost:5240/MAAS \$(maas apikey --username ${MAAS_PROFILE});bash"
```

### Run a rack controller

**Note:** *You will need to access an existing region or region+rack to get the MAAS "secret" to facilitate adding a rack controller to the existing MAAS region*

```
export MAAS_REGIOND_CONTAINER=maas
export MAAS_REGION_IP="$(docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' ${MAAS_REGIOND_CONTAINER})"
export MAAS_SECRET="$(docker exec ${MAAS_REGIOND_CONTAINER} cat /var/snap/maas/common/maas/secret && echo)"
export MAAS_CONTAINER_NAME=maas-rack
export MAAS_DOMAIN=craigbender.me
export MAAS_URL="http://${MAAS_REGION_IP}:5240/MAAS"

docker run \
  --rm \
  -it \
  --name ${MAAS_CONTAINER_NAME} \
  -h ${MAAS_CONTAINER_NAME}.${MAAS_DOMAIN} \
  --privileged \
  craigbender/cmaas:jammy-3.3 \
  "maas init rack --maas-url ${MAAS_URL} --secret ${MAAS_SECRET};bash"
  
```
<img width=1000 src="https://raw.githubusercontent.com/thinguy/containerized-maas/master/docker-ps.svg">

<img width=1000 src="https://raw.githubusercontent.com/thinguy/containerized-maas/master/maas-gui.svg">


## Build your own
#### Building Container
```
git clone https://github.com/thinguy/containerized-maas.git
cd containerized-maas
docker build -t cmaas:jammy-3.3 maas
```
### Retrieving MAAS Details
***
#### Retrieving MAAS API Key
```
docker exec ${MAAS_CONTAINER_NAME} maas apikey --username admin
```
##### Save API Key as variable for later re-use
```
API_KEY="$(docker 2>/dev/null exec ${MAAS_CONTAINER_NAME} maas apikey --username admin)"
```
#### Retrieving MAAS Region Secret
```
docker exec ${MAAS_CONTAINER_NAME} cat /var/snap/maas/common/maas/secret && echo
```
#### Retrieving Docker Internal IP
**NOTE**: *This IP address not for UI access, but for tasks such as adding additional rack controllers*
```
docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' ${MAAS_CONTAINER_NAME}
```
#### Login via MAAS CLI
(to enable CLI commands)
```
API_KEY="$(docker 2>/dev/null exec ${MAAS_CONTAINER_NAME} maas apikey --username admin)"
docker exec ${MAAS_CONTAINER_NAME} maas login admin http://localhost:5240/MAAS ${API_KEY}
```
### Common CLI Admin Tasks
***
*Ensure you are logged in first*
#### Set MAAS Name
```
docker exec ${MAAS_CONTAINER_NAME} maas ${MAAS_PROFILE} maas set-config name=maas_name value=cmaas
```
#### Set Upstream DNS
```
docker exec ${MAAS_CONTAINER_NAME} maas ${MAAS_PROFILE} maas set-config name=upstream_dns value=8.8.8.8
```
#### Disable DNSSEC Validation
```
docker exec ${MAAS_CONTAINER_NAME} maas ${MAAS_PROFILE} maas set-config name=dnssec_validation value=no
```
#### Global boot parameters to pass to the kernel by default
```
docker exec ${MAAS_CONTAINER_NAME} maas ${MAAS_PROFILE} maas set-config name=kernel_opts value='nomodeset console=tty0 console=ttyS0,1152008n'
```
### Accessing the UI
***
Visit http://{{docker host}}:5240/MAAS/ and login as ${MAAS_PROFILE}${MAAS_PASS}

