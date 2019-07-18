Overview
==================

MAAS Region/Rack Controller combo running in a systemd-enabled container.
NOTE: This is a work in progress.

Clone git repo
=============================

```
$ git clone https://github.com/ThinGuy/magenta-box.git
```

Building Container
=============================

```
$ cd magenta-box
$ sudo docker build -t "magenta-maas:1.0" maas-region-rack
```

Running Container
=============================

```
$ sudo docker run -d -p 5240:5240 -v /sys/fs/cgroup:/sys/fs/cgroup:ro --privileged --name maas-region-rack "magenta-maas:1.0"
```

Retrieving MAAS API Key
=============================

```
$ sudo docker exec maas-region-rack maas-region apikey --username admin
```

Retrieving MAAS Region Secret
=============================

```
$ sudo docker exec maas-region-rack cat /var/lib/maas/secret && echo
```

Retrieving Docker Internal IP
=============================

NOTE: This IP address not for UI access, but for tasks such as adding additional rack controllers

```
$ sudo docker inspect --format '{{ .NetworkSettings.Networks.bridge.IPAddress }}' maas-region-rack
```

Login via MAAS CLI
=============================

(to enable CLI commands)

```
$ docker exec maas-region-rack maas login admin http://localhost:5240/MAAS <API Key from above>
```

Common CLI Admin Tasks
=============================

Set MAAS Name

```
$ sudo docker exec maas-region-rack maas admin maas set-config name=maas_name value=maas-magenta
```

Set Upstream DNS

```
$ sudo docker exec maas-region-rack maas admin maas set-config name=upstream_dns value=8.8.8.8
```

Disable DNSSEC Validation

```
$ sudo docker exec maas-region-rack maas admin maas set-config name=dnssec_validation value=no
```

Global boot parameters to pass to the kernel by default

```
$ sudo docker exec maas-region-rack maas admin maas set-config name=kernel_opts value='nomodeset console=tty0 console=ttyS0,1152008n'
```

Skip MAAS UI Intro screens 

```
$ sudo docker exec maas-region-rack maas admin maas set-config name=completed_intro value=true
```

Add Ubuntu 16.04 (Xenial Xerus) as a OS choice

```
$ sudo docker exec maas-region-rack maas admin boot-source-selections create 1 os=ubuntu release=xenial arches=amd64 subarches=* labels=*
```

Add Ubuntu 19.04 (Disco Dingo) as a OS choice

```
$ sudo docker exec maas-region-rack maas admin boot-source-selections create 1 os=ubuntu release=disco arches=amd64 subarches=* labels=*
```

Add CentOS 6.6 as a OS choice

```
$ sudo docker exec maas-region-rack maas admin boot-source-selections create 1 os=centos release=centos66 arches=amd64 subarches=* labels=*
```

Add CentOS 7 as a OS choice

```
$ sudo docker exec maas-region-rack maas admin boot-source-selections create 1 os=centos release=centos70 arches=amd64 subarches=* labels=*
```

Start Image imports

```
$ sudo docker exec maas-region-rack maas admin boot-resources import
```


Access the UI
=============================

Visit http://<docker host>:5240/MAAS/ and login as admin/admin.
