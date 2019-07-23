FROM solita/ubuntu-systemd:18.04

ENV DEBIAN_FRONTEND=noninteractive
ENV container docker

# pre apt install locales and tzdata
RUN echo "locales locales/locales_to_be_generated multiselect en_US.UTF-8 UTF-8" | debconf-set-selections && \
	echo "locales locales/default_environment_locale select en_US.UTF-8" | debconf-set-selections && \
	echo "tzdata	tzdata/Areas	select	America" | debconf-set-selections && \
	echo "tzdata	tzdata/Zones/America	select	Los_Angeles" | debconf-set-selections && \
	echo "America/Los_Angeles" > /etc/timezone && \
	ln -s /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

# Don't start any optional services except for the few we need.
RUN find /etc/systemd/system \
         /lib/systemd/system \
         -path '*.wants/*' \
         -not -name '*journald*' \
         -not -name '*systemd-tmpfiles*' \
         -not -name '*systemd-user-sessions*' \
         -exec rm \{} \;
RUN systemctl set-default multi-user.target

RUN DEBIAN_FRONTEND=noninteractive apt 2>/dev/null -qq update && \
	DEBIAN_FRONTEND=noninteractive apt 2>/dev/null -yqq install apt-utils gnupg locales sudo software-properties-common && \
	DEBIAN_FRONTEND=noninteractive apt 2>/dev/null -yqq dist-upgrade && \
	apt-key 2>/dev/null adv --recv --keyserver keyserver.ubuntu.com 04E7FDC5684D4A1C && \
	echo 'deb http://ppa.launchpad.net/maas/next/ubuntu bionic main' > /etc/apt/sources.list.d/maas-next-bionic.list && \
	DEBIAN_FRONTEND=noninteractive apt 2>/dev/null -qq update && \
	DEBIAN_FRONTEND=noninteractive apt 2>/dev/null install -yqq \
	apt-transport-https \
	ca-certificates \
	curl \
	wget \
	jq \
	openssh-client \
	rsyslog
	
ENV LC_ALL="en_US.UTF-8"

RUN systemctl enable rsyslog.service && \
	service rsyslog restart && \
	DEBIAN_FRONTEND=noninteractive apt 2>/dev/null install -y maas && \
	maas-region createadmin --username admin --password admin --email admin@admin.org

# initalize systemd
CMD ["/sbin/init"]

