<img width=200 src="https://raw.githubusercontent.com/canonical/containerized-maas/master/containerized-maas.svg?sanitize=true">

# Overview
Provides a [Region, Rack, or Region+Rack](https://maas.io/docs/about-controllers) [MAAS](https://maas.io) Controller combo running in a systemd-enabled docker container.

You can build your own following the directions below or run the demo image from docker hub

**Caveats:**
 - This is a work in progress
 - This has not been through formal QA testing
 - This image is not officially supported
 - This runs as a privileged  container
 - This is a *Work in Progress*

**NOTE:** *For the remaining examples "${NAME}" is the name of the running container and can be changed to your liking.*

## Run from dockerhub
```
sudo docker run \
	-d \
	-p 5240:5240 \
	-v /sys/fs/cgroup:/sys/fs/cgroup:ro \
	-v /tmp:/images \
	--privileged \
	--name ${NAME} \
	craigbender/demo:containerized-maas.01
```
## Build your own
#### Building Container
```
git clone https://github.com/ThinGuy/containerized-maas.git
cd containerized-maas
sudo docker build -t "maas:1.0" maas-region-rack
```
#### Running Container
```
sudo docker run -d -p 5240:5240 -v /sys/fs/cgroup:/sys/fs/cgroup:ro --privileged --name ${NAME} "containerized-maas:1.0"
```
##### Running Container w/ remapped port
If you have another MAAS instance on the same docker host, want to run multiple instances on same host, etc., you can remap the default port per instance.
```
sudo docker run -d -p 8888:5240 -v /sys/fs/cgroup:/sys/fs/cgroup:ro --privileged --name ${NAME} "containerized-maas:1.0"
```
##### Running with local storage
In order to import custom images into MAAS. (i.e. Run this way if you plan to deploy windows, esx, rhel, etc)
```
sudo docker run -d -p 5240:5240 -v /sys/fs/cgroup:/sys/fs/cgroup:ro -v /tmp:/images --privileged --name ${NAME} "containerized-maas:1.0"
```
### Retrieving MAAS Details
***
#### Retrieving MAAS API Key
```
sudo docker exec ${NAME} maas-region apikey --username admin
```
##### Save API Key as variable for later re-use
```
API_KEY="$(sudo docker 2>/dev/null exec ${NAME} maas-region apikey --username admin)"
```
#### Retrieving MAAS Region Secret
```
sudo docker exec ${NAME} cat /var/lib/maas/secret && echo
```
#### Retrieving Docker Internal IP
**NOTE**: *This IP address not for UI access, but for tasks such as adding additional rack controllers*
```
sudo docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' ${NAME}
```
#### Login via MAAS CLI
(to enable CLI commands)
```
API_KEY="$(sudo docker 2>/dev/null exec ${NAME} maas-region apikey --username admin)"
sudo docker exec ${NAME} maas login admin http://localhost:5240/MAAS ${API_KEY}
```
### Common CLI Admin Tasks
***
*Ensure you are logged in first*
#### Set MAAS Name
```
sudo docker exec ${NAME} maas admin maas set-config name=maas_name value=containerized-maas
```
#### Set Upstream DNS
```
sudo docker exec ${NAME} maas admin maas set-config name=upstream_dns value=8.8.8.8
```
#### Disable DNSSEC Validation
```
sudo docker exec ${NAME} maas admin maas set-config name=dnssec_validation value=no
```
#### Global boot parameters to pass to the kernel by default
```
sudo docker exec ${NAME} maas admin maas set-config name=kernel_opts value='nomodeset console=tty0 console=ttyS0,1152008n'
```
#### Skip MAAS UI Intro screens
```
sudo docker exec ${NAME} maas admin maas set-config name=completed_intro value=true
```
#### Add Ubuntu 16.04 (Xenial Xerus) as an OS choice
```
sudo docker exec ${NAME} maas admin boot-source-selections create 1 os=ubuntu release=xenial arches=amd64 subarches=* labels=*
```
#### Add Ubuntu 19.04 (Disco Dingo) as an OS choice
```
sudo docker exec ${NAME} maas admin boot-source-selections create 1 os=ubuntu release=disco arches=amd64 subarches=* labels=*
```
#### Add CentOS 6.6 as an OS choice
```
sudo docker exec ${NAME} maas admin boot-source-selections create 1 os=centos release=centos66 arches=amd64 subarches=* labels=*
```
#### Add CentOS 7 as an OS choice
```
sudo docker exec ${NAME} maas admin boot-source-selections create 1 os=centos release=centos70 arches=amd64 subarches=* labels=*
```
#### Start Image imports
```
sudo docker exec ${NAME} maas admin boot-resources import
```
### Accessing the UI
***
Visit http://{{docker host}}:5240/MAAS/ and login as admin/admin.

