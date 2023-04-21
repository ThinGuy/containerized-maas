ARG BASE_OS=22.04

# Download and repack snapd with a replacement squashfs-tools to
# fix a bug with mksquashfs when packing a built snap.
# See: https://bugs.launchpad.net/snapd/+bug/1733598
FROM ubuntu:22.04 as snapd

ENV DEBIAN_FRONTEND=noninteractive
ENV LDFLAGS=-static
ENV PATH="$PATH:/snap/bin"
# Run apt-get commands together to always ensure apt-get update is run
# before using apt-get install to avoid issues with stale apt caches.
RUN apt-get update -qq && \
	apt-get dist-upgrade --yes && \
	apt-get install --yes -qq --no-install-recommends \
		fuse \
		gnupg \
		python3 \
		snapd \
		sudo \
		systemd \
		build-essential \
		git \
		help2man \
		zlib1g-dev \
		liblz4-dev \
		liblzma-dev \
		liblzo2-dev

# Fetch and compile squashfs-tools
RUN git clone https://github.com/plougher/squashfs-tools.git
RUN cd squashfs-tools && \
	git checkout 4.5.1 && \
	sed -Ei 's/#(XZ_SUPPORT.*)/\1/' squashfs-tools/Makefile && \
	sed -Ei 's/#(LZO_SUPPORT.*)/\1/' squashfs-tools/Makefile && \
	sed -Ei 's/#(LZ4_SUPPORT.*)/\1/' squashfs-tools/Makefile && \
	sed -Ei 's|(INSTALL_PREFIX = ).*|\1 /usr|' squashfs-tools/Makefile && \
	sed -Ei 's/\$\(INSTALL_DIR\)/$(DESTDIR)$(INSTALL_DIR)/g' squashfs-tools/Makefile && \
	cd squashfs-tools && \
	make -j$(nproc) && \
	make install

# Download and unpack snapd
RUN mkdir -p /snap/snapd/current
RUN snap download snapd
RUN unsquashfs -f -d /snap/snapd/current snapd_*.snap

# Replace mksquashfs and unsqusahfs with our own
RUN cp /usr/bin/mksquashfs /snap/snapd/current/usr/bin
RUN cp /usr/bin/unsquashfs /snap/snapd/current/usr/bin

# Repack snapd
RUN mksquashfs /snap/snapd/current /snapd.snap


# Prepare the filesystem to copy into a blank image
FROM ubuntu:${BASE_OS} as base

ENV DEBIAN_FRONTEND=noninteractive
ENV PATH="$PATH:/snap/bin"

# Run apt-get commands together to always ensure apt-get update is run
# before using apt-get install to avoid issues with stale apt caches.
RUN apt-get update -qq && \
	apt-get dist-upgrade --yes && \
	apt-get install --yes -qq --no-install-recommends \
		build-essential \
		fuse \
		gnupg \
		python3 \
		snapd \
		sudo \
		systemd

# Clean apt lists because we'll be copying the entire filesystem to a blank image
RUN apt-get clean
RUN rm -rf /var/lib/apt/lists

# Ensure snapd's system-key file exists
RUN touch /var/lib/snapd/system-key

# stop udevadm from working
RUN dpkg-divert --local --rename --add /sbin/udevadm
RUN ln -s /bin/true /sbin/udevadm

# remove systemd 'wants' triggers
RUN rm -f \
		/etc/systemd/system/*.wants/* \
		/lib/systemd/system/local-fs.target.wants/* \
		/lib/systemd/system/multi-user.target.wants/* \
		/lib/systemd/system/sockets.target.wants/*initctl*

# remove everything except tmpfiles setup in sysinit target
RUN find \
		/lib/systemd/system/sysinit.target.wants \
		\( -type f -or -type l \) -and -not -name '*systemd-tmpfiles-setup*' \
		-delete

# remove UTMP updater service
RUN rm -f /lib/systemd/system/systemd-update-utmp-runlevel.service

# disable /tmp mount
RUN rm -vf /usr/share/systemd/tmp.mount

# disable most systemd console output
RUN echo ShowStatus=no >> /etc/systemd/system.conf

# disable ondemand.service
RUN systemctl disable ondemand.service

# set basic.target as default
RUN systemctl set-default basic.target

# enable the services we care about
RUN systemctl enable snapd.service
RUN systemctl enable snapd.socket


# The actual snapcraft image
FROM scratch

# Set the proper environment.
ENV container=docker \
	init=/lib/systemd/systemd
ENV PATH="$PATH:/etc/profile"



# Copy the entire filesystem from the base image
COPY --from=base / /

# Copy the snapd snap from the snapd image
COPY --from=snapd /snapd.snap /snapd.snap

# Add our entrypoint
ADD entrypoint.sh /bin/
ADD systemd-detect-virt /usr/bin/

# Ensure docker sends the shutdown signal that systemd expects
STOPSIGNAL SIGRTMIN+3

# Set our entrypoint
ENTRYPOINT ["/bin/entrypoint.sh"]

# Set our default command
CMD ["maas"]
